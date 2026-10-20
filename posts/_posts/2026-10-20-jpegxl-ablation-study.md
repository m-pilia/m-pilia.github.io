---
layout: post
title: A small libjxl ablation study
subtitle: Finding out what makes a JPEG XL encoder good
image: /posts/img/jpegxl_ablation/scalpels.jpg
image-license:
  text: "Image: Spekta (public domain)"
  url: https://commons.wikimedia.org/wiki/File:Various_scalpels.png
show-avatar: false
mathjax: true
tags: [JPEG XL, image processing, GPGPU]
---

Despite it being a very busy period, lately I have been spending a bit of
background time thinking about how to improve
[cujpegxl](https://github.com/m-pilia/cujpegxl/), the GPU-accelerated JPEG XL
encoder I described in a [previous
post](https://martinopilia.com/posts/2026/09/07/gpu-jpegxl-codec.html). My next
planned step involves three phases: a runtime optimization of the current
version, followed by a feature extension to improve bit-per-pixel (bpp) at
fixed quality (or vice versa), then again followed by a further runtime
optimization of the extended code.

A useful lever for this project is the existence of a mature and robust
open-source reference implementation of the JPEG XL algorithm in
[libjxl](https://github.com/libjxl/libjxl). In order to decide which features
to prioritize, I conducted a small ablation study on the libjxl encoder to see
the impact of various parts of the algorithm on the resulting bpp, whose
results are described in this post.

Note that cujpegxl is an AI-heavy project, and most of the code and tooling
around it is AI-generated. It is not vibe-coding however, but rather a
seriously engineered project.

# Background

cujpegxl is a JPEG XL encoder that runs entirely on the GPU and its main
ambition is speed, aimed at real-time applications on (relatively) constrained
devices. In its first[^1] iteration, it compresses 4K frames in about 50 ms on
a GTX 1080 Ti, which is still far from the desired performance.

Given the complexity of the JPEG XL algorithm, speed here comes at a price. At
equal visual quality, the cujpegxl output can be up to 40–50% larger than
libjxl's, since the latter runs a complete (and slower) version of the
algorithm. In the current version of cujpegxl, notable exclusions include:
* Entropy coding is prefix-only. rANS coding is not implemented.
* LZ77 pre-pass is omitted.
* No non-square, <8 and >32 transforms.
* No iterative Butteraugli rate control.
* No optimized coefficient orders.

Some numerical approximations and simplifications are also made for performance
reasons, trading a bit of quality for speed:
* Huffman codes limited to 15 bit.
* Transform selection uses a simpler heuristic.
* Fuzzy erosion is local (clamped to a 32px tile) as opposed to global.
* Fixed-size 32-cluster map, with one histogram per group, as opposed to the
  full greedy cost-driven clustering of 7425 contexts performed by libjxl.
* DCT coefficients stored as FP16.
* Uniform field quant calibration.
* Fixed-strength inverse Gaborish pre-sharpening.
* Simplified CfL estimation.

# Study setup

Since cujpegxl already implements a subset of libjxl, the study targets a
limited subset of algorithm parts, using as baseline libjxl at effort 7. Each
experiment disables a specific feature, and measures the difference in bpp with
respect to the baseline.

Since not all features are directly controllable through the libjxl API, this
experiment uses a [small
patch](https://github.com/m-pilia/libjxl/commit/5d4a659cf9c850afe50d52919713d47d7c4c2648)
adding some toggles to disable the algorithm's parts of interest.

The study sweeps over nine quality values, from Butteraugli distance 0.5 to 4.0 and
experiments with 20 variants, for a total of 720 image encodings.

## Dataset

The dataset used here is the [four 4K image
set](https://github.com/m-pilia/cujpegxl/tree/bffb5c167f7e9e1ea3f36eea9067ae76593d9e16/data)
used for iterative development in cujpegxl. It is admittedly small and does not
give strong statistical significance to the results, but it allows for fast
iteration, which greatly helps.[^2]

## Ablation variants

The ablated parts in the experiments can be roughly grouped into four categories.
- Entropy coding:
  * Forcing Huffman coding over rANS.
  * Number of context clusters.
  * Coefficient ordering.
  * LZ77 pre-pass.
  * Block context map size.
- Filters and quantization:
  * Per-block quantization adjustment.
  * Quantization deadzone.
  * Gaborish smooting/pre-sharpening.
  * Edge-preserving filter (EPF).
  * Adaptive EPF strength.
  * Adaptive chroma-from-luma (CfL)
- Transforms and their block sizes:
  * Limit block size to 8x8, 16x16, or 32x32.
  * Include rectangular blocks.
  * Include smaller blocks (2x2, 4x4, 4x8).
  * Include alternative transforms (identity, AFV).
  * Include larger blocks (64x32, 64x64).
- Perceptual rate control
  * Butteraugli feedback.

## Metrics

The metrics used for evaluation are the usual: Butteraugli (which libjxl is
tuned for, and therefore inherently biased), SSIMULACRA2 (a state-of-the-art
perceptual metric), and PSNR (non-perceptive, but a widely used metric that
gives us some measure of pixel-level error).

For each variant and metric, the bpp-vs-quality curve is drawn, then compared
with the baseline curve (from libjxl effort 7). The Bjøntegaard Delta rate
(BD-rate) {% cite bjontegaard2001calculation %} is then computed and reported
for each metric. A positive change of +x % means that removing the ablated
feature makes the compressed codestream x % larger (and therefore worse
compression rate), while a negative change means an improvement in compression
rate.

## Results

The plot below shows the BD-rate change for each ablated part. Here the
whiskers denote minimum and maximum, given the small dataset sample. Note that
each variant is tested in isolation, so interaction between parts is not
accounted for in this study (as testing the full matrix of combinations would
take too much time).

When reading the BD-rate plot, a positive change represents a worsening of the
compression rate over the baseline (libjxl effort 7), a negative change
represents an improvement. Since we are removing features from the encoder, we
expect changes to be on the positive side (regressions), except for the
addition of Butteraugli loop control (from libjxl effort 8), which instead adds
a feature not present on the baseline and is therefore expected to be an
improvement.

<div class="center-block"
     style="width: 100%; text-align: center; font-size: 80%;">
    <img src="/posts/img/jpegxl_ablation/plot_1.png" markdown="1"/>
</div>

## Entropy coding

Entropy coding immediately strikes as the dominant source of bpp improvement,
where both rANS and increasing the number of context clusters give comparable
improvements. This is expected, as Huffman coding allocates at least one bit
per symbol, while rANS allows allocating sub-bit amounts per symbol. It is also
valuable as it represents a purely lossless source of compression rate
improvement. The risk coming with it is the complexity of optimizing it on GPU,
and making sure that the implementation comes without completely blowing up the
runtime budget.

libjxl tracks thousands of contexts, defining sets of properties characterizing
a block, and it groups them into clusters that share a probability table.
Allowing for a finer-grained clustering allows for a substantial bpp
improvement. However, falling back to a simpler search method over the default
one makes no difference on this dataset.

Compared to the two changes above, coefficient order makes a much smaller but
consistent improvement, while LZ77 pre-pass and adaptive context map made no
meaningful difference.

We can also visualize how the effect of these features is more pronounced at
lower quality (i.e. higher target compression rate), where it is therefore
possible to achieve substantially larger wins:

<div class="center-block"
     style="width: 100%; text-align: center; font-size: 80%;">
    <img src="/posts/img/jpegxl_ablation/plot_2.png" markdown="1"/>
</div>

## Quantization and filters

Playing with quantization and filter features shows some interesting results,
albeit smaller and less straightforward as we start seeing the different
metrics diverge.

A feature of libjxl is the so-called deadzone quantization, which rounds small
values to zero a bit more eagerly than ordinary rounding. It is a consistent
win of 0.5-3%, and should be a cheap addition to cujpegxl (which currently only
uses regular rounding).

Per-block adaptive quantization gives a relatively large improvement to
Butteraugli and a smaller one to the PSNR, but it does not seem to improve
SSIMULACRA2 on these data.

JPEG XL uses a Gaborish smoothing filter in the decoder, and the encoder
compensates for it by pre-sharpening the image (for which cujpegxl uses a fixed
pre-sharpening strength). Ablating the Gaborish pre-sharpening indicates that
the feature is improving both Butteraugli and PSNR, but actually has the
opposite effect on SSIMULACRA2 (at least on this dataset).

JPEG XL also uses a separate edge-preserving filter (EPF) to smooth the
compression artifacts. The filter itself is actually applied by the decoder,
but the encoder is responsible for deciding how many filter passes to run and
for building a per-block sharpness map. Ablation suggests that on this dataset
the EPF has a small positive impact on Butteraugli but not a significant one on
the other metrics. Moreover, adaptive EPF strength seems to have only a very
limited impact.

## Block sizes

JPEG XL can choose from about a few dozen transform block sizes and shapes,
ranging from 2x2 to 256x256. Restricting libjxl to just 8x8, 16x16 and 32x32
(as cujpegxl currently does) worsens file sizes by less than 1 %. Adding back
any single family of shapes among the ones under test improves the result by at
most ±1.5 %. That is a rather limited change and within the variation among
individual images.

Adding extra shapes is a relatively low hanging fruit, but also a relatively
low value one.

## Butteraugli feedback loop

The impact of adding Butteraugli loop control (libjxl effort 8) gives an
interesting albeit expected result. It gives a big improvement in BD-rate on
the Butteraugli distance (the metric it is optimizing, and therefore biased
towards), and a measurable but much smaller improvement for other metrics.

It however adds a huge runtime cost, making the libjxl encoder over six times
slower compared to effort 7, so it is unlikely to be viable on a high
performance implementation, short maybe of a single-shot approach rather than
an iterative one like in libjxl.

# Conclusions

The results are quite telling, and suggest a way to prioritize additions to
cujpegxl. Most of the bpp gain is in entropy coding, where rANS addition and
higher context cluster count alone represent most of the attainable overall
improvement. The caveat is that rANS has a fair share of complexity and it is
non-trivial to make GPU friendly. Increasing the number of context clusters can
potentially be a lower hanging fruit if sticking to a static fixed number of
clusters, while switching to a dynamic count would require a bit more
implementation work and an additional runtime cost. Quantization fixes should
then follow, especially considering how most of them are fairly cheap and easy
to implement. Increasing the variety of block sizes is also quite easy but
likely to give lower gains, especially on unbiased metrics. Finally,
Butteraugli rate control is very expensive and can be considered last, if at
all.

Note that this study is not meant as a general evaluation of the libjxl
encoding front-end. The results are intentionally limited to a small dataset
and therefore they do not correctly represent the performance of libjxl
features in the general case. Moreover, features that only seem to give minor
contributions can still be relevant for a general purpose codec for a format
with a very high scope and domain of application such as JPEG XL. In fact this
study has a very specific and narrow scope, being solely aimed at identifying
and prioritizing candidates for extension and optimization of cujpegxl.

# References

{% bibliography --cited %}

# Footnotes
{:footnotes}

[^1]: And self-admittedly still immature.

[^2]: Even on such a small dataset size, the study took about half an hour of
    compute.
