---
layout: post
title: Entropy coding improvements in cujpegxl
subtitle: Increasing compression rate while making runtime faster
image: /posts/img/jpegxl_entropy/entropy.png
image-license:
  text: "Image: Own (public domain)"
show-avatar: false
mathjax: true
tags: [JPEG XL, image processing, GPGPU]
---

Following up on the ablation study presented in a [previous
post](https://martinopilia.com/posts/2026/10/20/jpegxl-ablation-study.html), I
worked on integrating additional parts of the JPEG XL algorithm in cujpegxl,
especially around entropy coding. This post presents an outline of the changes,
and shows the improvements in BD-rate and runtime speed.

Moreover, last week a new and promising GPU-accelerated JPEG XL encoder called
[gjxl](https://github.com/yunho-c/gjxl) was published {% cite yunho2026gjxl %},
so I decided to take a look at it and perform some quick comparative analysis.

# Background

[cujpegxl](https://github.com/m-pilia/cujpegxl) is a GPU-accelerated JPEG XL
encoder that I developed to support some real-time use cases on constrained
devices, where the slow runtime of existing JPEG XL implementations would be
completely unviable. Unlike other projects, cujpegxl does not aim for either
feature parity or byte-equality with libjxl, but rather aims to build a GPU-
and real-time-friendly version of the algorithm, where approximations that
trade small amounts of compression rate are acceptable if they bring
substantial speed-up.

cujpegxl started from a limited subset of the JPEG XL algorithm that placed
itself roughly halfway between libjxl and nvJPEG in the quality/compression
space, and a still relatively slow runtime.[^1] Next steps in my work aim at
moving the curve towards full JPEG XL, while at the same time making the
runtime closer to nvJPEG.

In a sense, cujpegxl is not really directly competing with libjxl, as the
latter is not tailored for real-time applications. It rather aims to be a
replacement for nvJPEG with much better compression rate at equal quality while
still being competitive with it in terms of runtime.

# Implemented optimizations

The already presented [ablation
study](https://martinopilia.com/posts/2026/10/20/jpegxl-ablation-study.html)
dissected the main algorithmic knobs that were still missing from the early
cujpegxl implementation:

<div class="center-block"
     style="width: 100%; text-align: center; font-size: 80%;">
    <img src="/posts/img/jpegxl_ablation/plot_1.png" markdown="1"/>
</div>

As evident from the plots, entropy coding is the biggest and most immediate and
consistent source of potential BD-rate improvement, and was therefore the
main focus of this iteration. Deadzone quantization is also a cheap and simple
improvement, that I selected as starting point.

## Deadzone quantization

Deadzone quantization is a technique used in libjxl to make the encoder
more keen on discarding small quantization coefficients. The name comes from
the fact that a "dead zone" is used to extend the range of coefficients that
are rounded down compared to standard rounding (half a quantization step). For
instance, in libjxl the Y channel quantization uses two thresholds, 0.56 at
lower frequencies (more conservative) and 0.62 at higher frequencies.

Rounding down more eagerly increases the number of zeros and therefore makes
the coefficients more compressible. It also affects the quality in a slightly
negative way, but overall the trade-off is around 2-8% lower bit rate at
equivalent quality.

Runtime-wise, it makes the quantization kernel very slightly slower, but thanks
to reducing the amount of downstream work (due to more coefficients being
zeroed) the overall impact is a nice 1.5-3% speedup of the encoder.

## EPF leaf

JPEG XL stores per-block settings alongside the coefficients, and these
settings include a field for the edge-preserving filter (EPF) strength.[^4]
cujpegxl currently uses a constant strength, therefore it wastes one bit to
store a constant. Hard-coding a dedicated split in the decision tree allows to
have a dedicated leaf for the EPF strength (as opposed to the data-driven
learned split in libjxl), with a negligible change in runtime and an easy
lossless reduction of compressed output size by 0.8-3%.

## ANS coding

The use of [Asymmetric Numerical Systems
(ANS)](https://en.wikipedia.org/wiki/Asymmetric_numeral_systems) is one of the
key improvements of JPEG XL over JPEG, and allows for a substantial (and
lossless) compression improvement over [Huffman
coding](https://en.wikipedia.org/wiki/Huffman_coding). The initial cujpegxl
implementation was limited to Huffman coding only, because ANS is rather
GPU-unfriendly and some attempts to implement it on the GPU were not
satisfactory.

Huffman coding assigns to each symbol a code that is at least one bit long,
while ANS allows codes to be smaller than one bit when working over sequences,
therefore enabling compression levels unattainable with Huffman coding. The
downside is that ANS requires a state for each group (an independently encoded
region), and since at 4K resolution only 135 groups exist, this does not allow
to efficiently saturate a large GPU.

I therefore decided to switch to a hybrid GPU/CPU processing model, with
front-end image processing and Huffman coding happening on the GPU, while ANS
coding is performed on the CPU. The GPU prepares tokens and histograms, with
each CPU worker then process two interleaved streams at a time.

One quality/speed trade-off is to only use ANS for AC coefficients,[^2] using
Huffman-only encoding for DC coefficients and metadata, as moving them to the
CPU would only offer a small compression improvement at the price of increased
runtime.

While the addition of ANS, with a preliminarily optimized implementation, adds
a substantial amount of runtime (45-90% slower if executed sequentially), this
pipelined approach allows to run the whole ANS coding in parallel on the
previously idle CPU cores, with pipelined parallelism compensating for both the
additional device-to-host traffic and the new CPU calculations, basically
keeping the throughput at the same level as the previous approach.[^3]

## Data-driven clustering

In JPEG XL, a context is a description of some characteristics of a symbol to
be encoded, such as colour channel, frequency, nearby non-zero coefficients,
etc., and since different contexts can have very different symbol frequencies,
clustering them allows ANS to have significantly better probability models.
libjxl performs a greedy data-driven clustering of the 7425 possible AC
contexts, while cujpegxl previously used only 32 fixed groups with shared
probability tables.

Now cujpegxl adds a data-driven and GPU-based clustering, and it uses a new
approach that differs from libjxl. It starts with a greedy idea analogous to
libjxl to populate the 32 starting models (still fewer than the 128 used by
libjxl). It then performs parallel assignment of contexts on the GPU in
parallel, using two refinement rounds of k-means clustering with [Lloyd's
algorithm](https://en.wikipedia.org/wiki/Lloyd%27s_algorithm), which allows to
avoid the sequential dependencies across contexts.

The addition of data-driven clustering granted a 4-5% reduction in compressed
output size, very close to the effectiveness of libjxl's own clustering method
despite of using fewer models and an approximate heuristic.

# Quality

I ran an evaluation of the new cujpegxl version, using the same 100
high-quality images from the previous evaluation, but this time running in
2160p instead of 1080p.[^5]

In this evaluation I report the three metrics (Butteraugli, SSIMULACRA2, and
PSNR) as usual, but I consider SSIMULACRA2 to be the most representative one,
as PSNR only considers raw pixel-level error without any perceptual aspects
(even if the pixel error is overall low, the error itself might be distributed
in ways that worsen quality compared to other algorithms), and Butteraugli is a
biased metric (because it is explicitly targeted for optimization by JPEG XL,
thus making comparison with other algorithms unfair).

<div class="center-block"
     style="width: 80%; text-align: center; font-size: 80%;">
    <img src="/posts/img/jpegxl_entropy/bpp_vs_ssimulacra2.png" markdown="1"/>
    <img src="/posts/img/jpegxl_entropy/bpp_vs_butteraugli.png" markdown="1"/>
    <img src="/posts/img/jpegxl_entropy/bpp_vs_psnr.png" markdown="1"/>
    cujpegxl and libjxl (effort 7) sweep over target Butteraugli distances 0.5, 0.7, 1.0, 1.3, 1.6, 2.0, 2.5, 3.0, 4.0. nvJPEG sweeps over quality levels 20, 30, 40, 50, 60, 70, 75, 80, 85, 90, 95, 100.
</div>

We can observe how the quality/compression curve is now much closer to libjxl,
and substantially better than nvJPEG. At Butteraugli distance level 1 cujpegxl
is very close to reference libjxl, and it falls off a bit at lower quality
settings, while still remaining significantly better than nvJPEG.

The overall BD-rate:[^10]

| Reference | SSIMULACRA2 | Butteraugli | PSNR   |
|-----------|------------:|------------:|-------:|
| libjxl    | +21.6%      | +33.9%      | +18.9% |
| nvJPEG    | −30.1%      | −26.7%      | −24.8% |

And a breakdown by compression settings:

| cujpegxl distance range | Reference | SSIMULACRA2 | Butteraugli | PSNR   |
|-------------------------|-----------|------------:|------------:|--------:|
| 0.5–1 (higher bitrate)  | libjxl    | +16.0%      | +51.5%      | +14.7% |
| 0.5–1                   | nvJPEG    | −32.6%      | −20.4%      | −22.5% |
| 1–2 (middle)            | libjxl    | +15.6%      | +28.4%      | +16.6% |
| 1–2                     | nvJPEG    | −30.4%      | −32.0%      | −25.2% |
| 2–4 (lower bitrate)     | libjxl    | +30.5%      | +37.0%      | +28.4% |
| 2–4                     | nvJPEG    | −29.4%      | −24.2%      | −25.7% |

# The new kid on the block: gjxl

Yesterday, while doing a bit of literature review, I stumbled upon a preprint
by Yunho Cho and Sangeon Jeon at Georgia Tech {% cite yunho2026gjxl %}, who
have also been working on GPU acceleration of JPEG XL.

gjxl was published about two months later than the first public version of
cujpegxl but, ironically, development of the two projects started about at the
same time (with cujpegxl being just one day older, having been started [on the
9th of August
2026](https://github.com/m-pilia/cujpegxl/commit/2d5e7405d64ab1050648206b89d21e4d5dedfb83),[^6]
while gjxl [dates to the
10th](https://github.com/yunho-c/gjxl/commit/69a2caab8dd1daf8bcf2321b5725d28057ae0769)).[^7]

gjxl is a very interesting project, with broader scope and different goals
compared to cujpegxl, and it shows some very good results. It targets both CUDA
and Metal backends. The key innovation in the paper over libjxl is CPU-GPU
pipelining, evaluating candidate DCT blocks in parallel on the GPU. The
Butteraugli rate control happens on the GPU. The design is overall quite
similar to cujpegxl.[^11]

gjxl not only improves speed over reference libjxl by a substantial 2.8x at
default effort (can be more, depending on the effort) but it also improves the
BD-rate (the authors report from -0.71% to -9.14% BD-rate, depending on the
effort setting, with -3.83% at the default effort 7):

<div class="center-block"
     style="width: 80%; text-align: center; font-size: 80%;">
    <img src="/posts/img/jpegxl_entropy/gjxl.png" markdown="1"/>
    Figure 2 from Cho and Jeon {% cite yunho2026gjxl %}.
</div>

<div class="center-block"
     style="width: 80%; text-align: center; font-size: 80%;">
    <img src="/posts/img/jpegxl_entropy/gjxl_efforts.jpg" markdown="1"/>
    Table 3 from Cho and Jeon {% cite yunho2026gjxl %}.
</div>

On the other hand, cujpegxl has slightly worse BD-rate compared to libjxl, but
it targets massively higher execution speed than gjxl[^8] and intentionally
trades off small amounts of BD-rate for very large runtime improvements.

Another important difference is in scope. gjxl implements a more or less
complete version of JPEG XL (minus modular mode), targets multiple platforms,
and, as already seen, it even strives to improve the BD-rate over the reference
implementation, potentially targeting a wide range of applications. On the
other hand, cujpegxl implements only a curated subset of JPEG XL and primarily
targets runtime speed for real-time execution on constrained devices. No effort
setting is provided: only what is strictly useful to fulfill the goal is
implemented,[^9] also to minimize maintenance cost (after all, this is a side
project I developed in just about two weeks of full-time equivalent work so
far), and the design willfully trades small losses in BD-rate in order to gain
runtime speed, as for my applications not being fast enough makes the
difference between being usable and being completely unviable.

# Runtime

I benchmarked the runtime of cujpegxl, taking as references three other
solutions:
* nvJPEG as a main direct competitor for high performance applications
* libjxl as the reference JPEG XL implementation
* gjxl as an alternative GPU-accelerated JPEG XL encoder

I ran the benchmark on a box equipped with a GTX 1080Ti, Ryzen 7 2700X, 64 GB
DDR4 memory, PCIe Gen3, trying to match compression settings that give roughly
the same output image quality.

At medium/high quality (SSIMULACRA2 ≈ 82):

| codec           | fps    |
|-----------------|--------|
| cujpegxl (d=1) | 251.57 |
| nvJPEG (q=90)   | 890.28 |
| gjxl (d=1.3)    | 4.71   |
| libjxl (d=1.3)  | 1.19   |

At low quality (SSIMULACRA2 ≈ 65):

| codec           | fps     |
|-----------------|---------|
| cujpegxl (d=3)  | 295.96  |
| nvJPEG (q=50)   | 1238.38 |
| gjxl (d=4)      | 5.47    |
| libjxl (d=4)    | 0.69    |

As we can see, cujpegxl is still significantly slower than nvJPEG, but it is
now in the same order of magnitude in terms of speed.

# Future work

There is still quite a bit of work ahead, and I am hoping to schedule more effort
in the near future. Quality-wise, there are still some of the levers from the
ablation study to reduce bpp that I have not implemented yet, and I am hoping
to figure out more improvements by re-evaluating some of the current solutions.
On the runtime front, I still need to review and optimize several parts of both
CPU and GPU code.

Moreover, a big and important slice of work that I have not even started
tackling is platform-specific optimizations targeting e.g. RTX or Tegra. So far
I have been optimizing only for basic architectural aspects, that are available
in older cards, but offloading work to tensor cores and moving to narrower math
width has potential to provide important benefits. 16-bit math alone has the
potential to almost double the throughput of some compute-intensive kernels,
while for instance it would worsen performance on older card families.

# References

{% bibliography --cited %}

# Footnotes
{:footnotes}

[^1]: The initial runtime was already significantly faster than libjxl, but the
    compression/quality values were different enough to make it hard to draw
    meaningful comparisons in terms of just runtime.

[^2]: To be clear, both ANS and Huffman are used, with a simple heuristic
    similar to libjxl that Huffman is only selected for degenerate cases.

[^3]: Latency is obviously increased, but throughput (with a reasonable
    latency) is the main metric for the kind of real-time applications I am
    targeting, as long as the latency remains well below the period for the
    target frame rate (15-30 Hz).

[^4]: A brief description of what the EPF does is present in the [previous
    post](https://martinopilia.com/posts/2026/10/20/jpegxl-ablation-study.html)
    on the ablation study.

[^5]: The whole evaluation took almost five hours of compute on my box.

[^6]: Interestingly, the very first piece of the project I implemented was the
    data and evaluation framework, before starting anything at all related to
    the feature code. This reflects a career working on numerical methods in
    industrial products.

[^7]: Both projects are younger than
    [jxl-gpu](https://github.com/imazen/jxl-gpu), the earliest open-source GPU
    port of JPEG XL I am aware of.

[^8]: Currently cujpegxl is over fifty times faster than gjxl and it is still
    far from being complete: there are many parts in need of further
    optimization (including GPU front-end kernel, quantization, and entropy
    coding), and I have not even started at all to implement
    architecture-specific optimizations, like tensor core math or FP16 math.

[^9]: In a typical
    [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it) way,
    which I live by. I might potentially expand the scope of the project later,
    but that will happen if new use cases arise in my target usage
    applications.

[^10]: Positive means cujpegxl uses more bits per pixel at equivalent quality,
    negative means the opposite.

[^11]: Some of the cujpegxl design features were implemented after the gjxl
    preprint was made available. However, cujpegxl has been developed
    independently and not inspired by it, I discovered the gjxl project only
    yesterday.
