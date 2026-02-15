---
layout: post
title: Making a real-world algorithm run twenty times faster
subtitle: A showcase of optimisation techniques from the trenches
image: /posts/img/runtime_optimisation/speed.png
image-license:
  url: https://commons.wikimedia.org/wiki/File:Hey,_take_it_easy_there,_Al_Unser_Jr!_(5774923418).jpg
  text: "Image: Wikimedia Commons (CC-BY-SA 2.0)"
show-avatar: false
mathjax: true
tags: [C++, optimisation]
---

This post is a summary of an interesting code optimisation task I performed for
a customer some time back. They had developed an algorithm for a product
but they were way over budget on runtime, and due to the embedded and real-time
nature of their product, not meeting the runtime budget meant the product would
simply not work.

My job was to take their code, which I had never seen before, and tweak it to
run a lot faster. In this task I managed to apply a wide range of different
optimisation techniques, which I think made it a very interesting showcase.

# Background

I knew nothing about this product, and the code came with no documentation at
all. The very first course of action, therefore, was to understand what the
software was doing by reading the source code of tests and implementation.

For context, the algorithm took as input a large collection of data samples and
a list of candidate object detections, and it iterated over the candidates to
perform some [least squares](https://en.wikipedia.org/wiki/Least_squares) model
fitting on each object.

After getting an idea of what the code was doing, I could proceed with
benchmarking its baseline performance, compile a list of candidate
optimisations, prioritise them, and then implement some of the changes until
reaching the desired performance. Meeting the desired runtime budget required
to make the code twenty times faster than its baseline version.

I used two main sources of input for decision-making:
- Micro-profiling output to identify bottlenecks and other optimisation candidates.
- High-level conceptual knowledge to identify alternative approaches.

The candidate optimisation steps fell into three broad categories:
- Mathematical improvements to the algorithm, replacing sub-algorithms with
  more cost-efficient alternatives but without significantly altering the
  result.
- Optimizing data structures.
- Code optimisation and low-level techniques.

After defining the candidate optimisations, I prioritised the preliminary list
based on cost-benefit, with the more-bang-for-the-buck coming first, and more
involved (or risky) optimisations placed further down the line.

Naturally, this work did not happen through a fixed or static plan, but rather
in an iterative fashion. With the removal of each former performance
bottleneck, while cycling between optimisation and profiling, new bottlenecks
are iteratively identified in what is left of the program runtime, leading to
more optimisation ideas.

# Speedup

The following table is a summary of all optimisation steps in the order I
performed them, including the approximate reduction in runtime (relative to the
previous step) and the cumulative speedup (including all steps up to that
point). The table gives a bird's eye view of the work, while the next sections
will explore each individual step in more detail.

| Change                         | Runtime reduction[^4] | Cumulative speedup[^20] |
|--------------------------------|:---------------------:|:-----------------------:|
| Ensure inlining                | 29%                   | 41%                     |
| Optimise indexing calculations | 9%                    | 55%                     |
| Avoid unnecessary copies       | 19%                   | 91%                     |
| Switch to single precision     | 11%                   | 115%                    |
| Data structure optimisation    | 52%                   | 347%                    |
| Avoid multiple passes          | 44%                   | 699%                    |
| Replace median with mean       | 32%                   | 1074%                   |
| SIMD vectorisation             | 34%                   | 1579%                   |
| Approximate reciprocal         | 11%                   | 1899%                   |
| Avoid unnecessary zeroing      | 5%                    | 2004%                   |


Note that this is neither a comprehensive list of optimisation techniques, nor
a list of "must do". What I am describing here is a real case encountered in a
real industrial product, not some artificial example, and the methods used are
the ones fitting this problem best. Under different circumstances your mileage
may vary, some of these optimisations might not be relevant, while others not
mentioned here might be more important.

# Optimisation steps

## Step 0a: Make sure you have tests

Optimisation, just like refactoring, comes with a huge risk of introducing bugs
and regressions. Making this kind of changes without a systematic way to
protect yourself from regressions is a recipe for disaster.

Thankfully, this product came with a reasonably comprehensive suite of unit
tests verifying its behaviour, and the tests even ran reasonably fast. This
allowed me to quickly iterate with the classic change-build-test loop, making
sure that nothing would break in the process.

## Step 0b: Make sure you have a representative benchmark

In order to optimise a piece of software you need to be able to measure its
performance, and in order to measure performance you need a representative
benchmark. Coming up with a meaningful and representative benchmark is probably
the trickiest part of software optimisation.

The benchmark needs to be representative of the intended workload. In the case
of real-time systems, the product must have a worst-case time bound, and the
benchmark needs to reproduce worst-case conditions. This requires identifying
the region of the input domain that would trigger such conditions.

The benchmark needs to perform enough work to produce statistically significant
results, making sure that repeated work is not cancelled by caching effects or
similar, while not significantly affecting the performance of the software
being measured (you want to measure performance of the product, not of the
benchmark itself).

Measurements need to be performed with the target compiler, running on the
target hardware (and operating system, if any). Sometimes, what may be a good
optimisation on one platform might actually degrade performance on a different
platform. You must use the target compiler flags and optimisation options: you
want the compiler to do most of the work for you, so working under different
compilation settings would be completely meaningless.

Input initialisation, cache state, and any kind of warm-up effects are some
basic examples of what the benchmark needs to take into account so as to not
produce completely worthless (if not counterproductive) results.

## Step 0c: Make sure you have the right profiling tools

In principle, any reliable profiler can get the job done and enable good
optimisations. However, finer-grained micro-profiling can give much more
detailed information and significantly simplify the job.

Profiling tools can be standalone products (like SystemView, that can be used
on more or less any bare-metal platform) or can be shipped by the system
vendor. For operating systems, profilers can even be directly baked into the
kernel. For example, the Linux kernel includes
[perf](https://en.wikipedia.org/wiki/Perf_%28Linux%29), Windows comes with
[Event Tracing](https://en.wikipedia.org/wiki/Event_Viewer) (ETW), NVidia
provides Nsight, and most other systems ship with similar tools.

Profilers like the ones mentioned allow, among other things, measuring time
spent inside each function by capturing samples of the call stack, which
provides a detailed and fine-grained allocation of runtime within the
application.

Captured profiling data is useless without a visualisation. A common way to
display and analyse call data is by generating a [flame
graph](https://web.archive.org/web/20260204194316/https://www.brendangregg.com/flamegraphs.html).
Flame graphs not only allow to easily grasp how runtime is distributed, but
also give a quick overview of what the call stack looks like, hinting for
example at what parts of the software might be suffering from too much function
call overhead.

## Step 1: Ensure inlining

One of the first things I noticed when looking at the flame graph was the
presence of some deep call stacks in unexpected places. The software used a
real-time linear algebra library providing vector and matrix types and
operations through template classes and functions. It struck me how many of
these operations were not being inlined, generating many nested calls to
internal library routines, which I suspected added a significant overhead.

Moreover, this library was used inside hot loops, in some places by creating
vector objects as local loop variables, which upon inspection of the assembly
turned out to introduce additional copies.

```c++
for (std::int32_t y{}; y < height; ++y)
{
    for (std::int32_t x{}; x < width; ++x)
    {
        linear_algebra::Vector2 const position{
            static_cast<double>(x),
            static_cast<double>(y),
        };
        auto const estimate = a * (input.at(x, y) - position) + b;
        auto const error = estimate - data.at(x, y);
        double const error_norm = linear_algebra::norm(error);

        // ...
    }
}
```

Analogously, some internal functions called from hot loops used these vector
types in their interface

```c++
struct Fit
{
    linear_algebra::Vector2 a;
    linear_algebra::Vector2 b;

    double loss(linear_algebra::Vector2 const& input, linear_algebra::Vector2 const& data) const
    {
        // ...
    }
};
```

which would then be called on specifically constructed vector objects inside
hot loops

```c++
fit.loss({input1, input2}, {data1, data2});
```

Removing the vector objects, preventing unnecessary copies in their
construction and ensuring inlining of scalar operations, caused a significant
improvement.[^5]

In the specific case, manually inlining these operations was a quick and easy
optimisation to perform (hence being at the top of my list), requiring me to
only modify half a dozen lines in a couple places of the code, yet it caused a
reduction of the total program runtime close to thirty percent.

```c++
for (std::int32_t y_index{}; y_index < height; ++y_index)
{
    for (std::int32_t x_index{}; x_index < width; ++x_index)
    {
        double const x{static_cast<double>(x_index)};
        double const y{static_cast<double>(y_index)};
        double const estimate_x{a_x * (input_x[x_index] - x) + b_x};
        double const estimate_y{a_y * (input_y[y_index] - y) + b_y};
        double const error_x{estimate_x - data_x[x_index]};
        double const error_y{estimate_y - data_y[y_index]};
        double const error_norm{std::sqrt(std::pow(error_x, 2) + std::pow(error_y, 2))};

        // ...
    }
}

struct Fit
{
    double a_x;
    double a_y;
    double b_x;
    double b_y;

    double loss(double const input_x, double const input_y, double const data_x, double const data_y) const
    {
        // ...
    }
};
```

This is obviously not a universal solution. While in this context the impact on
code quality was minimal, in different situations manual inlining might lead to
code duplication or to reinventing the wheel. There might be other
alternatives, such as switching to a different linear algebra library that
suffer less from function call overhead, or switching to a different compiler
that does a better job at inlining. Switches of this kind, however, are
sometimes not feasible within the constraints of real-world systems.

## Step 2: Optimise integral indexing calculations

For the next step, I noticed how a non-negligible amount of runtime was spent
in a function performing some data resampling.

```c++
std::int32_t index(std::int32_t const x, std::int32_t const y)
{
    always_enabled_assert((x >= MIN_X) and (x <= MAX_X));
    always_enabled_assert((y >= MIN_Y) and (y <= MAX_Y));
    auto const scaled_x{std::floor((x - OFFSET_X) / static_cast<double>(SCALE_X))};
    auto const scaled_y{std::floor((y - OFFSET_Y) / static_cast<double>(SCALE_Y))};
    return (WIDTH * static_cast<std::int32_t>(scaled_y)) + static_cast<std::int32_t>(x);
}
```

That prompted some simple integer arithmetic optimisations, such as removing
unnecessary conversions and moving some assertions from production to debug builds.

```c++
std::int32_t index(std::int32_t const x, std::int32_t const y)
{
    debug_assert((x >= MIN_X) and (x <= MAX_X));
    debug_assert((y >= MIN_Y) and (y <= MAX_Y));
    std::int32_t const scaled_x{(x - OFFSET_X) / SCALE_X};
    std::int32_t const scaled_y{(y - OFFSET_Y) / SCALE_Y};
    return (WIDTH * scaled_y) + x;
}
```

This simple optimisation shaved off close to ten percent of the runtime. Of
course there are additional ways to reduce the amount of indexing work, but
they will be captured in the next steps.

## Step 3: Avoid unnecessary data copies

[Function purity](https://en.wikipedia.org/wiki/Pure_function) and [referential
transparency](https://en.wikipedia.org/wiki/Referential_transparency) are
valuable properties that are generally good to enforce in interface design, as
they make functions much safer to reason about, leading to less error-prone and
more malleable code (especially, but not limited to, when dealing with
concurrency).

It is important however to remember that C++ is not Haskell, and the C++
compiler has more limited optimisation opportunities when it comes to passing
larger data types by value. So sometimes purity can come at a great cost if one
is not careful.

An example I found in this program was a function computing an order statistic
over a vector of data. It was taking the vector by copy, allowing the
implementation to sort the elements without affecting the caller.

```c++
double order_statistic(Vector<double> data) {...}
```

This sounds good in theory, but since this program was operating on relatively
large data vectors, the cost of the copy was non-negligible. In fact, I spotted
this issue by noticing a large amount of time being spent inside `memcpy` in
the flame graph.

Considering that this function was internal, and not part of any public API,
burdening it with a side effect on its input could be acceptable, as long as it
was well documented.

```c++
/// @attention This function sorts its input data
double order_statistic(Vector<double>& data) {...}
```

Adding a single character to the code might look like a small change, but it
shaved off an additional 19% from the runtime at this stage.

## Step 4: Switch to single precision

You might have noticed how the examples so far involved double-precision
arithmetic. That aroused my suspicion, as the types of algorithms used in this
program did not strike me as calculations that would benefit from the
additional digits of double precision types. Changing `double` to `float`, as
expected, caused no meaningful change in the quality of the output results,
while reducing runtime by about one tenth.

Reducing the arithmetic type width has also the benefit of doubling the
throughput of SIMD registers, which will come to play a few steps later.

## Step 5: Optimise data structures

The next optimisation step was not directly prompted by profiling, but rather
by observing the structure of the program.

There were two different parts of the program performing two separate passes
over the input data (stored as a bidimensional array). The second loop looked
something like this:

```c++
for (std::int32_t y_index{}; y_index < height; ++y_index)
{
    for (std::int32_t x_index{}; x_index < width; ++x_index)
    {
        if (!is_relevant_sample(x_index, y_index))
        {
            continue;
        }

        float const x{static_cast<float>(x_index)};
        float const y{static_cast<float>(y_index)};
        float const position_x{input_x[x_index] - x};
        float const position_y{input_y[y_index] - y};
        float const estimate_x{(a_x * position_x) + b_x};
        float const estimate_y{(a_y * position_y) + b_y};
        float const error_x{estimate_x - data_x[x_index]};
        float const error_y{estimate_y - data_y[y_index]};
        float const error_norm{std::sqrt(std::pow(error_x, 2) + std::pow(error_y, 2))};

        // ...
    }
}
```

Pre-processing the data could reduce the amount of required calculations, by
avoiding the need to repeat some simple calculations (including calculation of
indices) in the second pass. Additionally, the preprocessing step can take care
of discarding irrelevant data samples, allowing to remove some branching from
hot loops that consume the data.

Switching to a more suitable data structure
([array-of-structures](https://en.wikipedia.org/wiki/Array_of_structures)) to
store the preprocessed data also allowing to take advantage of data locality
and enabling better cache usage.

```c++
struct Element
{
    float position_x;
    float position_y;
    float data_x;
    float data_y;
};

// ...

for (auto const& element : elements)
{
    float const estimate_x{(a_x * element.position_x) + b_x};
    float const estimate_y{(a_y * element.position_y) + b_y};
    float const error_x{estimate_x - element.data_x};
    float const error_y{estimate_y - element.data_y};
    float const error_norm{std::sqrt(std::pow(error_x, 2) + std::pow(error_y, 2))};

    // ...
}
```

While on the surface this change does not seem to remove much from the logic,
its combined effects halved the remaining runtime of the program.

Note that this data structure is not compatible with SIMD vectorisation. But
the target compiler does not support automated SIMD vectorisation, so this is
not a degradation. We will revisit SIMD vectorisation a few steps later.

## Step 6: Avoid multiple passes

One thing that caught my attention was how the software was performing multiple
passes of the top-level algorithm, which in a nutshell looked a bit like this:

```c++
Result main_routine(containers::static_vector<Data> const& data)
{
    Result result{};
    for (std::size_t i{}; i < ITERATIONS; ++i)
    {
        top_level_algorithm(data, result);
    }
    return result;
}
```

Multi-pass algorithms, iteratively refining the result by applying the same
algorithm multiple times, each time taking as input the result from the
previous pass, are quite common in numerical analysis, especially when working
with geometric methods.

What piqued my interest is how a two-pass approach was used with a fairly high
level algorithm, which I suspected would not yield much benefit while almost
doubling the runtime of the product.

So switching to a single-pass approach, with only minimal adjustments to the
logic, allowed to cut the runtime by over 40% without causing meaningful
changes to the quality of the output.

I see this as a good example of premature optimisation (of output quality)
that straight turns into a performance pessimisation (of runtime).

## Step 7: Replace median with mean

The median is well-known in [robust statistical
estimation](https://en.wikipedia.org/wiki/Robust_statistics) for being a robust
[centrality](https://en.wikipedia.org/wiki/Central_tendency) estimator,
significantly less sensitive to outliers compared e.g. to the sample mean. The
downside of the median, however, is that it can be significantly more expensive
to estimate compared to the sample mean. While the mean can be easily
estimated[^6] in $$O(n)$$ and can easily benefit from caching and data
parallelisation, calculating the median usually requires[^7] $$O\left(n
\log(n)\right)$$ and makes heavier use of branching.

In this algorithm, however, the median was being used to produce an initial
centrality estimate for the input data distribution, which was then fed as
input to a subsequent step of the algorithm. Here I also suspected premature
pessimisation. Indeed, experimenting with it I observed that using the sample
mean would not degrade the quality of the results in any meaningful way, while
reducing the overall runtime by almost a third.

Note that I do not advocate for blindly using the mean as a centrality
estimator, especially in places where outliers can be an issue. Robustness of
the estimation has to be weighted against the cost: in some applications the
resilience of the median can be a necessity, while in other cases (like in this
example) the mean is going to be good enough.

## Step 8: SIMD vectorisation

[SIMD](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data)
vectorisation was naturally one of the first improvements I thought of. I left
it as a later step however because, as we have seen so far, there were several
lower-hanging fruits that required less effort to be implemented. Nonetheless,
vectorisation is such a valuable optimisation and there is generally no good
reason to _not_ go for it.

When it comes to SIMD vectorisation, the first and foremost suggestion is to
let the compiler do it for you as much as possible. Modern compilers are able
to vectorise [a lot of different
patterns](https://web.archive.org/web/20260105144240/https://gcc.gnu.org/projects/tree-ssa/vectorization.html)
without requiring any changes from the developer's side. For example, when
using a gcc-compatible compiler, running with `-O2` (or `-ftree-vectorize`),
together with a suitable architecture flag, will enable automatic
vectorisation. Adding the `-ftree-vectorizer-verbose=5` and
`-fopt-info-vec-missed` flags will make the compiler log to console what parts
of the code (mainly loops) it managed to vectorise and, more importantly, which
ones it did not.

For example, let assume we have a reduction operation implemented suboptimally
as follows[^10]

```c++
std::int32_t suboptimal_reduction(std::array<std::int32_t, 1024U>& data)
{
    for (std::uint32_t i{1U}; i < data.size(); ++i)
    {
        data[i] += data[i - 1U];
    }

    return data.back();
}
````

The loop carries a dependency across iterations, and the compiler will point the problem
out to us. Compiling with `g++ -O2 -ftree-vectorizer-verbose=5
-fopt-info-vec-missed` will produce something like:

```
simd.cpp:3:33: missed: couldn't vectorize loop
simd.cpp:5:17: missed: not vectorized, possible dependence between data-refs MEM <struct array>
```

Getting rid of the dependency[^21]

```c++
std::int32_t reduction_without_dependencies(std::array<std::int32_t, 1024U> const& data)
{
    std::int32_t sum{};

    for (auto const x : data)
    {
        sum += x;
    }

    return sum;
}
```

will indeed make the compiler emit vector instructions, for instance on ARMv8

```
        vmov.i32   q8, #0  @ v4si
        add        r3, r0, #4096
.L6:
        vld1.32    {q9}, [r0]!
        vadd.i32   q8, q9, q8
        cmp        r0, r3
        bne        .L6
        vadd.i32   d7, d16, d17
        vpadd.i32  d7, d7, d7
        vmov       r0, s14 @ int
        bx         lr
```

Addressing the impediments pointed out by the compiler, when feasible,[^8]
allows to get more vectorisation done for free. There are however some patterns
that cannot be reasonably auto-vectorised by today's compilers,[^9] and in that
case case a different approach is needed. A simple example is represented by
many kinds of loops involving floating point arithmetic: since floating point
operators are not associative, the compiler is not allowed to perform most
kinds of re-ordering unless unsafe math optimisations are enabled (and there
are many cases where enabling them is undesirable).

If automatic vectorisation is not sufficient, the next step I would recommend
is to consider using a vectorising DSL, for instance
[Halide](https://en.wikipedia.org/wiki/Halide_(programming_language)) or
[ISPC](https://github.com/ispc/ispc). It will save quite a lot of work and at
the same time produce much cleaner, readable, and maintainable code compared to
manual vectorisation. These tools, however, might not always be an option, e.g.
they might not be available for a particular platform, or might be disallowed
by other constraints of the project.[^11] And even if those tools are available,
they might still not be able to implement some very specific patterns.

If other avenues are exhausted, manual vectorisation is still an option. For
obvious portability reasons, together also with maintainability and
readability, I strongly discourage hard-coding platform-specific intrinsics in
your code (or at least, in the business logic). Using a SIMD abstraction
library will make the code both portable and cleaner. Example libraries are
[eve](https://github.com/jfalcou/eve),
[xsimd](https://github.com/xtensor-stack/xsimd), or
[highway](https://github.com/google/highway). C++26 introduces
[std::simd](https://en.cppreference.com/w/cpp/experimental/simd.html), bringing
native support within the STL.

After having clarified this context, back to the subject. In my particular
problem, the target compiler did not support automatic vectorisation,[^12] the
project was C++14, so no `std::simd` yet,[^15] and using third party libraries
was not an option. The solution was to use an in-house developed SIMD
abstraction library, and manually vectorise the code.

The structure of one of the hot loops, after our previous data structure
optimisation step, was roughly along these lines

```c++
struct Element
{
    float position_x;
    float position_y;
    float data_x;
    float data_y;
};

// ...

for (auto const& element : elements)
{
    float const estimate_x{(a_x * element.position_x) + b_x};
    float const estimate_y{(a_y * element.position_y) + b_y};
    float const error_x{estimate_x - element.data_x};
    float const error_y{estimate_y - element.data_y};
    float const error_norm{std::sqrt(std::pow(error_x, 2) + std::pow(error_y, 2))};

    // ...
}
```

While the
[array-of-structures](https://en.wikipedia.org/wiki/Array_of_structures) is
beneficial in terms of data locality, it is incompatible with vectorisation as
it prevents vector load/store operations. The way I had structured the code in
the previous steps would, however, easily allow to switch between AoS and
SoA.[^13]

```c++
struct Elements
{
    alignas(CACHE_LINE) std::array<float, SIZE> position_x;
    alignas(CACHE_LINE) std::array<float, SIZE> position_y;
    alignas(CACHE_LINE) std::array<float, SIZE> data_x;
    alignas(CACHE_LINE) std::array<float, SIZE> data_y;
};

// ...

std::int32_t const vector_count{ceil(data_length / simd_vector_size)};

for (std::int32_t i{}; i < vector_count; ++i)
{
    simd_lib::vector<float> const x{simd_lib::load_aligned(x, i)};
    simd_lib::vector<float> const y{simd_lib::load_aligned(y, i)};
    simd_lib::vector<float> const data_x{simd_lib::load_aligned(elements.data_x.data(), i)};
    simd_lib::vector<float> const data_y{simd_lib::load_aligned(elements.data_y.data(), i)};
    simd_lib::vector<float> const position_x{simd_lib::load_aligned(elements.position_x.data(), i)};
    simd_lib::vector<float> const position_y{simd_lib::load_aligned(elements.position_y.data(), i)};

    simd_lib::vector<float> const estimate_x{(a_x * position_x) + b_x};
    simd_lib::vector<float> const estimate_y{(a_y * position_y) + b_y};
    simd_lib::vector<float> const error_x{estimate_x - data_x};
    simd_lib::vector<float> const error_y{estimate_y - data_y};
    simd_lib::vector<float> const error_norm{simd_lib::sqrt((error_x * error_x) + (error_y * error_y))};

    // ...
}
```

Note how the abstraction library does not just make the code portable but also
significantly easier to read (and write). Note how to go from scalar to
vectorised we mostly just need to replace array access with load operations,
and change the data type from `float` to `simd_lib::vector<float>`.[^1]

Note also how we do not explicitly deal with leftover elements that do not fit
in a full vector at the end of the loop. This saves us from the need of
unrolling the remaining elements (or to add a separate scalar loop after the
vectorised loop). The trick I used is to fill the excess elements in the
incomplete input vector with padding values that will cancel themselves out in
the calculations, leaving the result unaffected. This is both more efficient
and leads to simpler code.

## Step 9: Approximate reciprocal

One of the hot loops above contained a reciprocal operation

```c++
for (...)
{
    float const weight{1.0F / error_norm};
}
```

Floating point division/reciprocation is a fairly expensive arithmetic
operation, so it would be good if we could replace it with something faster.
Thankfully there is a neat solution to this problem.

Finding the reciprocal `x` of some number `y` means finding a value `x` such
that

$$
y = \frac{1}{x}
$$

This problem is equivalent to finding the root of

$$
f(x) = \frac{1}{x} - y
$$

[Newton's method](https://en.wikipedia.org/wiki/Newton%27s_method) provides a
sequence $$x_n$$ converging (with quadratic rate) to the root of $$f(x)$$

$$
x_{n + 1} = x_n - \frac{f(x_n)}{f'(x_n)}
$$

and since $$f'(x) = - \frac{1}{x^2}$$

$$
x_{n + 1} = x_n \left( 2 - y x_n \right)
$$

This is known as [Newton-Raphson
division](https://en.wikipedia.org/wiki/Newton-Raphson_division). Given an
initial guess $$x_0$$, it is possible to get an approximation of the reciprocal
with just two multiplications and one subtraction for each iteration.

The initial guess can be computed with `vrecpeq_f32` on Arm Neon or
`_mm_rcp_ps` on SSE2,[^3] and a Newton-Raphson iteration is also accelerated on
Neon with `vrecpsq_f32`.[^2] Given the fast rate of convergence of the method,
two Newton-Raphson iterations are enough to cover all significant digits of a
single-precision floating point value,[^14] and a single iteration can be
sufficient in many practical use cases.

With this in mind, I could implement a `simd_lib::approximate_reciprocal`
function using the relevant intrinsics, which allowed to replace the exact
reciprocal

```c++
for (...)
{
    simd_lib::vector<float> const weight{simd_lib::approximate_reciprocal(error_norm)};
}
```

The code contained a single division in a hot loop, but even just replacing
that one division with an approximate reciprocal (using a single Newton-Raphson
iteration) reduced the runtime of the product by about 11%, without any
significant impact on the quality of the output.

## Step 10: Avoid unnecessary zeroing

Looking again at the flame graph after the previous step, it caught my
attention how a non-negligible amount of time was now spent inside `memset`.
Reason for this was due to using a fixed-size vector container[^16] which,
dutifully, zero-initialised the storage before constructing its elements in
place.

```c++
containers::static_vector<Fit, FIT_COUNT> fit_models{...};
```

Zeroing the memory before constructing an object (or after destructing it) is a
generally good practice, but in high-performance contexts it is important to be
aware of the overhead it causes. In this case, switching to a container like
`std::array` for storage allowed to avoid the extra cost of memory
initialisation, with no significant downside.[^17]

```c++
std::array<Fit, FIT_COUNT> fit_models{...};
```

# Bonus optimisations

At this point, the software was meeting the customer's performance goals. I
however still had a few optimisations planned that could have allowed to reduce
the runtime even further if needed. And, on top of them, it would likely have
been possible to find more ways to optimise the software by just iterating
profiling and flame graph analysis.

I had left these optimisations to the end because of their worse cost-benefit
ratio, due to either requiring more work to be implemented when compared to the
other steps, or because of the higher potential to affect the quality of the
output and consequently requiring some tuning or trade-offs.

## Stochastic optimisation

When dealing with optimisation problems, [stochastic
optimisation](https://en.wikipedia.org/wiki/Stochastic_optimization) is a
powerful technique that can greatly reduce runtime when dealing with larger
problems.

It could have been applied to the least squares method used in this software by
accumulating the terms of the normal equation on a random subset of input
samples, instead of iterating over the whole input vector. When the input
vector is large enough, this method can significantly reduce runtime without
noticeably affecting the quality of the model fit on average.

To avoid introducing non-determinism in the system and ensuring easy
reproducibility of results, the "random" sampling can be performed using a
seeded sequence, for instance computing the seed based on timestamp or some
checksum of the input.[^19]

While being a powerful technique in general, I kept stochastic optimisation on
a low priority tier not just because of its potential impact on the quality of
the result (which makes it not a cost-free optimisation), but also because its
runtime benefit diminishes when interacting with other optimisations.

For instance, to fully benefit from downsampling, it would not be enough to
follow the naïve approach and select individual samples from the data, but it
would rather be required to sample whole cache lines (keeping vector and cache
alignment in mind). However, taking sequences of adjacent samples biases the
sampling and requires attention to make sure that it does not impact the
quality of the result.

## Switch to L1 norm

The algorithm computed norms in a few different places to measure closeness of
vectors. One possible way to make this algorithm faster could have been to
replace usage of the [L2 norm with the L1
norm](https://en.wikipedia.org/wiki/Lp_space).

This has however some pros and cons[^18] that would likely have required some
validation and potentially needed some tuning, and since I expected a limited
runtime improvement from it, I kept this optimisation low in the priority list.

## Gather-scatter of vector inputs

The software used some vector inputs

```c++
struct Sample
{
    float x;
    float y;
    float z;
};

std::array<Sample , SIZE> samples{...};
```

Vectorisation of one loop taking this kind of array as input could have been
optimised with
[gather-scatter](https://en.wikipedia.org/wiki/Gather/scatter_(vector_addressing))
operations.

This would have however required some relatively involved additional work. With
the need of following the restrictions in the safety guidelines, packaging this
particular optimisation under their project's constraints would have required
refactoring of some interfaces, which in turn would cascade more changes in
other parts of the product.

Given that I only expected a fairly limited speedup from this optimisation, I
significantly de-prioritised it with respect to other actions.

# Conclusions

This work package struck me not just as an interesting showcase of variegated
optimisation techniques, but also as a demonstrative example of what
bottlenecks and suboptimal design look like in real products.

Some of the techniques I used are high-performance coding technical
optimisations that come from expertise (e.g. dealing with vectorisation,
inlining, or any domain-specific algorithmic considerations), but others
definitely struck me as lower-hanging fruits whose avoidance should not require
as much experience (e.g. avoiding data copies or other unnecessary work).

It is also a reminder of how, in many products, other considerations come into
play, some of them fairly domain-specific (e.g. safety guidelines) and others
more generic (e.g. balancing cost of design and maintainability vs pure speed).
In real applications, chasing runtime speed for the sake of it can be
detrimental if done without context, while it is tempting to think that faster
simply equals better, making changes to a product can have associated costs
(possibly even in the long term).

To be good at optimising software products, it is important not just to
understand the technicality of how to make software run faster, but even more
so to understand how to do it without adding complexity (even just in terms of
making the code harder to read) nor creating maintenance costs.

# Footnotes
{:footnotes}

[^1]: Could be `auto`, but I make it more explicit for clarity.

[^2]: Looking at the names of intrinsics, it should be clear why a SIMD
      abstraction library helps with readability.

[^3]: Notably, the SSE2 and Neon instructions produce different results. So an
      interesting part of this task was to implement a software emulation of
      `vrecpeq_f32` producing bitwise exact results for testing and simulation
      purposes on non-Arm platforms. This was made easy by the fact that the
      Arm documentation includes pseudocode of the full instruction
      specification.

[^4]: Relative to the previous step.

[^5]: The downside of inlining vector operations is the repetition of logic
      across elements, but duplication can be avoided by moving the logic of
      individual operations into auxiliary functions that are guaranteed to be
      inlined instead (not included in these examples for brevity and clarity).

[^6]: In the number of input elements.

[^7]: A naïve approach using comparison-based sorting has an average $$n
      \log(n)$$ complexity. A more sophisticated approach would be to use
      [quickselect](https://en.wikipedia.org/wiki/Quickselect), with a
      complexity of $$n$$ in the average case and $$n \log(n)$$ in the worst
      case. An approximate
      [median-of-medians](https://en.wikipedia.org/wiki/Median_of_medians)
      estimation has a worst-case complexity of $$n$$. All these methods are
      slower than estimating the arithmetic mean in practice.

[^8]: Typical impediments that can be refactored away include loop-carried
      false [data
      dependencies](https://en.wikipedia.org/wiki/Loop_dependence_analysis),
      [aliasing](https://en.wikipedia.org/wiki/Aliasing_(computing)), branching
      inside loops, non-inlined function calls, unsupported or too complex
      [gather-scatter](https://en.wikipedia.org/wiki/Gather/scatter_(vector_addressing)),
      unclear loop bounds.

[^9]: These include some algorithms such as prefix sums, other non-trivial
      reduction operations, non-trivial data-dependent gather-scatter,
      branching inside loops, etc.

[^10]: This is actually a [prefix sum](https://en.wikipedia.org/wiki/Prefix_sum).

[^11]: Lack of safety qualification is a common reason in safety-critical application.

[^12]: Technically, the compiler implemented some automatic vectorisation, but
       the compiler's safety manual disallowed its usage in safety-critical
       applications.

[^13]: It would also be possible to combine the benefits of AoS and SoA, by
       having an array-of-structure-of-array, where the fields of each
       structure are arrays of one SIMD vector's size each.

[^14]: Except maybe for the correct rounding of the last digit.

[^15]: Note also that, at the time, `std::simd` was still far from being
       standardised, and C++26 was still years away.

[^16]: Similar in fashion to `std::inplace_vector` from C++26.

[^17]: For a container with fixed allocated size but variable number of
       elements, using a vector-like interface has some benefits, as it makes
       the code cleaner and less error-prone by internally managing the number
       of valid entries.

[^18]: For instance, the L1 norm is generally more robust to outliers, but it is
       not differentiable.

[^19]: Note that this will be terrible advice if any part of your algorithm is
       security-related and requires cryptographically strong RNG. Here I could
       safely assume that choices in how to perform calculations in the
       algorithm I was optimising had no security impact whatsoever.

[^20]: Relative to the baseline, which is already enabling all applicable
       compiler optimisation flags.

[^21]: This is written as a loop for the sake of explanation, but normally one
       would use `std::accumulate` in its place.
