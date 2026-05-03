---
layout: post
title: AI-driven C++ runtime optimization
subtitle: Case study of LLM-driven optimization in the wild
image: /posts/img/ai_runtime_optimisation/ann_speed.png
image-license:
  url: https://commons.wikimedia.org/wiki/File:Artificial_neural_network.svg
  text: "Image: Own, derived from Cburnett (GFDL)"
show-avatar: false
mathjax: false
tags: [C++, optimization, AI]
---

A few weeks ago I wrote a lengthy post about [making a real-world algorithm run
twenty times
faster](https://martinopilia.com/posts/2026/02/15/runtime-optimization.html).
There I talked about a work package performed several years ago, well before
LLMs were any useful as coding assistance tools. While writing I started asking
myself: what if, instead of being performed by an expert human, this work would
have been automated with an LLM?

I decided to put that idea to the test.

# Background

A bit more than one year ago I [wrote an op-ed
post](https://martinopilia.com/posts/2025/01/25/ai-oped.html) with my vision on
AI-assisted coding at the time. Long story short, I had been extensively
experimenting with LLMs for a long time, and while I noted some usefulness I
was still seeing relatively limited value in the context of high-quality
engineering of complex and high-integrity systems (which constitutes most of my
daily work).

In the last year the landscape has evolved. Many people argue that AI
development has massively accelerated in the last six months or so. My take is
actually quite different, I think AI development has slowed down and the
incremental improvement in quality of the trained models themselves is smaller
compared to a few years ago (where in earlier stages models were showing big
improvements in short iterations). What has however significantly improved in
the last 6-12 months is the engineering effort around models to create AI
assistance solutions that are "smarter" and more effective.

I personally use LLMs quite extensively and I have a good feel for their
strength and limitations when used as a tool by an expert senior developer. I
feel the real change for me personally in the last year is how most of these AI
tools went from being situationally useful[^9] to slowly becoming useful for
real and started saving time and effort in a more substantial manner, albeit
with limitations.

In the field of embedded automotive it is harder to consistently get
high-enough quality output from AI agents, especially in the kind of complex
domains (with functional safety impacts) on which I regularly work. For this
reason, often AI agents in my daily work are less useful to write production
code, and more useful to work on tooling, research, and adjacent problems.

Nonetheless, I am always interested in stepping up the game and finding
interesting challenges to come up with improvements and new ways in my
workflow. Lately I have been interested in challenging AI agents with more and
more complex tasks and try to see how far I can push them in a context where
code quality is extremely sensitive.

# Goals (and non-goals)

The idea of this experiment was to get a feel for the state of real-world
AI-driven C++ code runtime optimization. Emphasis on "driven", not "assisted".
Therefore I am not interested in using the LLM as a crutch to write code
faster, or in feeding my ideas to the LLM and see how it implements them.

What I really want is to see how the agent would fare if it had to replace the
human developer in an autonomous fashion, without relying on expert inside from
the user. It is the agent's responsibility to figure out what needs to be done
to make the code run faster.[^1]

I am also interested in a complex real-world problem, not in synthetic or
artificial examples, and in this sense the optimization problem from [my
previous
post](https://martinopilia.com/posts/2026/02/15/runtime-optimization.html) was
a very good test bench, as it provided a complex domain problem and allows for
a very broad range of optimization techniques to be applied.

Another important aspect to stress out: this experiment is _not_ a
human-vs-machine competition, and the goal is not to pick winners but rather to
evaluate the current status of AI-driven C++ optimization on real-world
problems in projects with high quality standards.

# Experiment setup

I managed to checkout and build the software component in the state it was
before my previous optimizations. This allowed comparisons with a common
baseline. I provided the agent with instructions on how to build the software
and run relevant unit tests, all in a single command.

I also packaged a script that would allow to build and run the runtime
benchmark under a profiler, producing a robust runtime estimation and clean
micro-profiling output in a structured JSON format, following what is
considered best practice for LLM consumption.

```json
{
  "profile": {
    "samples": 183568
  },
  "top_functions": {
    {
      "name": "float my_namespace::my_function<float, 256U>(float const x, float const y)",
      "samples": 7930,
      "percent": 22.16
    },
    ...
  },
  "top_call_paths": {
    {
      "stack": [
        "__start",
        "__libc_start_main",
        "main",
        ...
        "float my_namespace::my_function<float, 256U>(float const x, float const y)"
      ],
      "samples": 7930,
      "percent": 22.16
    },
    ...
  },
  "call_graph": {
    {
      "from": "__start",
      "to": "__libc_start_main",
      "samples": 37963
    }
    ...
  }
}
```

I used Claude Opus 4.6, which was the latest and greatest I had enterprise
access to at the time, with 200k token context window.

## Prompt

I structured the experiment in three prompts:

- First I tasked the agent to analyze the code, to prime the context a bit,[^7]
  and make a list of potential optimization opportunities, without making any
  changes to the code yet, and creating a markdown file with an analysis
  result.
- Then I tasked the agent to try implementing and verifying optimizations,
  using the benchmark as a decision criterion on whether to accept or reject an
  optimization attempt (creating a git commit for each accepted change), and
  documenting all attempts into a markdown file.
- Lastly I tasked the agent to keep iterating to find more optimization
  opportunities driven by micro-profiling data.

In this, I provided the agent with some ground rules:
- Freely change internal interfaces but do not alter public interfaces (of
  which we have no control), providing some additional indication of what
  constitutes a public interface.
- Strict binary equality of the results is not needed, there is leeway for
  small differences in floating point output as long as the results are
  reasonably close.
- I pointed at some useful tools (such as SIMD abstraction library).

# Speedup

I performed a few runs of the experiment, and picked the one providing the best
results. Background on the nature of the task and on human made optimization
approaches can be found in the [previous
post](https://martinopilia.com/posts/2026/02/15/runtime-optimization.html).

What follows is a table summarizing the optimizations discovered and accepted
by the AI agent. Of these, two were functionally incorrect from a logical
standpoint and would break or impair the software functionality, therefore I
disregarded them from the cumulative speedup.

| Change                                   | Runtime reduction[^2] | Cumulative speedup[^3]  |
|------------------------------------------|:---------------------:|:-----------------------:|
| Single precision (partial) + squaring    | 2.6%                  | 103%                    |
| Logic shortcut                           | 1.3%                  | 104%                    |
| Single pass                              | 30.5%                 | 150%                    |
| Hoisting                                 | 3%                    | 154%                    |
| ~~Reduce iterations~~                    | ~~30.1%~~             |                         |
| Cache float operations                   | 2.3%                  | 158%                    |
| Arithmetic shortcut                      | 2.3%                  | 162%                    |
| Replace median with mean                 | 48.2%                 | 311%                    |
| Squared norms                            | 4.6%                  | 327%                    |
| Clean up self-created issues             | 1.2%                  | 331%                    |
| ~~Remove least squares~~                 | ~~33.3%~~             |                         |
| Vectorization of secondary loops         | 7.4%                  | 357%                    |
| Vectorization of main hot loop           | 21.2%                 | 454%                    |

The final result was a 454% speedup. Quite far from the desired 20x speedup
needed to be able to bring the code to production. But despite of the failure
to meet the goal, this experiment was far from uninteresting, and it produced a
lot of useful insights.

# Results

The following is a brief overview of the agent's findings and adopted
solutions. The session took about five hours and the whole agent's "monologue"
was very long.

## Single precision (partial) + squaring

The first optimization figured out and accepted by the LLM was to switch a
couple small and simple functions from double to single precision, and replace
some Euclidean norms with squared norms in a loop. This produced a 2.6% runtime
reduction from the baseline.

```c++
double distance(double const x, double const y, ...)

// New LLM-generated code
float squared_distance(float const x, float const y, ...)
```

This was a good albeit small optimization, and logically makes sense. My main
objection is not on the merit but rather on the quality of the implementation,
as the agent happily added duplicated code in single precision instead of
refactoring the existing double-precision functions (e.g. into a template).
This is the low quality and poorly maintainable code that I would expect from a
fairly clumsy junior rather than any senior developer. Happily creating code
duplication has been a quite consistent behaviour with LLMs.

One thing to note, and that will be a repeating theme, is how the LLM tried
repeatedly and in multiple occasions to go from double precision to single
precision.[^4] It however never managed to switch the whole component to single
precision, trying instead to switch piecemeal and unavoidably choking in issues
due to inconsistency across different parts of the program, and in the end it
only managed to switch limited pieces of the code to single precision.

## Logic shortcut

Part of an algorithm dealt with large inputs, capping the number of samples
used for each processed input object to a maximum count. The downsampling
performed to cap the size used an intermediate buffer for calculations.

```c++
for (auto const& object : objects)
{
    std::size_t const object_area{...};

    if (object_area >= threshold)
    {
        // Downsample
    }

    // Continue processing
}
```

An interesting optimization performed by the LLM was to skip this step
altogether for objects below the threshold.

```c++
for (auto const& object : objects)
{
    std::size_t const object_area{...};

    if (object_area < threshold)
    {
        // Direct copy to output buffer
    }
    else
    {
        // Downsample in intermediate buffer
    }

    // Continue processing
}
```

This provided a fairly small speedup (1.3% runtime reduction over the previous
step), but at the same time it was an interesting idea, and for once it was
implemented into a reasonably clean manner.

If I had to optimize this myself, I would have probably attacked the problem at
a deeper level and reworked the logic to refactor out the intermediate buffer
altogether in all cases, which would have also simplified the code from a
maintenance standpoint. Nonetheless, this was an underlying reasonable idea and
implemented in a reasonable manner, without worsening the quality of the code.

## Single pass

Similar to the human-performed optimization, the agent identified the
possibility of switching from double-pass to single-pass, which provides a
substantial speedup (30.5% incremental speedup in this case).

## Hoisting

The next couple optimizations found and accepted by the agent involved
[hoisting some variables out of
loops](https://en.wikipedia.org/wiki/Loop-invariant_code_motion). This was
overall a small improvement (about 3% speedup total) and in some instances I am
surprised the change actually made any difference at all.

## Reduce iterations

The agent tried to reduce the maximum number of allowed least squares
iterations, it realized it was improving runtime and, by its own admission, it
decided that remaining iterations were only relevant for "pathological" cases
and therefore could be discarded.

While this change would reduce runtime by about 30%, it would naturally have a
negative impact on the quality of the implementation, reason behind my decision
of discarding such optimization from the results. This example shows a (rather
unsurprising) lack of common sense in the decision-making from the agent.
Moreover, a more sensible way to attack this problem would have been to revisit
the termination criteria rather than bluntly lowering the maximum iteration
cap.

Perhaps this could have been avoided if automated tests executed by the LLM
also captured some deeper output quality performance aspects of the algorithm,
that are often only accounted for by performance KPIs on larger datasets rather
than at unit test level.

## Cache float operations

A clever but ugly optimization performed by the agent was to "cache" some
operations

```c++
class Object
{
    double compute(...)
    {
        float const x{static_cast<float>(object.x)};
        float const y{static_cast<float>(object.y)};
        ...
        float const residual{a * (x - x_0) + b * (y - y_0) + ...};
    }
};
```

by adding a stateful cache to a class and storing some intermediate values

```c++
class Object
{
    double compute(...)
    {
        float const residual{a * (x_ - x_0) + b * (y_ - y_0) + ...};
        ...
    }

    float x_;
    float y_;
    ...

    void update_cache()
    {
        _x = static_cast<float>(x);
        _y = static_cast<float>(y);
        ...
    }
};
```

In some sense I admire the wicked idea, but it turns the code into an
error-prone stateful mess. And the runtime improvement is really small (2.3%
incremental runtime reduction), not even close to the amount of speedup that
could be achieved by proper fixes.

But the real problem is another: this is a good example of very shallow changes
that fix a symptom rather than the cause of a problem. A much better result
could be achieved by restructuring the calculations to get rid of the casts
between single- and double-precision, rather than caching them like this, which
is basically just adding insult to injury.

So technically this makes the program faster, but overall makes the software
worse (and hard to clean up and optimize later for real).

## Arithmetic shortcut

The next optimization to be discovered and accepted was also small (2.3%
runtime reduction) but reasonable (and, code-quality-wise, poor but not
completely unhinged).

In a piece of code like this

```c++
float const diff_x{input_x - (model_x + c * (data_x - estimate_x))};
float const diff_y{input_y - (model_y + c * (data_y - estimate_y))};
return diff_x * diff_x + diff_y * diff_y;
```

the agent identified that, when the `c` factor in the product is zero, some
calculations can be skipped

```c++
float const diff_x{input_x - model_x};
float const diff_y{input_y - model_y};
if (c != 0.0F)
{
    flaot const dx{input_x - (model_x + c * (data_x - estimate_x))};
    flaot const dy{input_y - (model_y + c * (data_y - estimate_y))};
    return dx * dx - dy * dy;
}
return diff_x * diff_x + diff_y * diff_y;
```

The agent obviously botched the implementation, as `diff_x` and `diff_y` are
not used in the early return path and should therefore not be computed before
evaluating the `if` condition. This code also introduces other problems with
high-integrity coding, as exact inequality comparison of floating point values
is not allowed, and therefore would still be rejected by static analysis.[^5]

## Replace median with mean

As already seen in the human-performed optimization, getting rid of median
calculations in favour of mean was a quite important part of the speedup.

The agent struggled for a long time trying to optimize median calculations.
Most of the failures were due to the fact that one of the unit tests duplicated
some of the production code logic (testing some parts against a copy of
itself). This is a type of unit tests that I deem to be of low quality and low
value, but in this instance it had the additional drawback of confusing the
agent.

At the end of the lengthy autonomous prompt execution, I gave the agent some
steering,[^6] hinting it to keep that test's logic consistent with the tested code,
which allowed it to unblock itself and finally manage to replace the median
with a mean estimate (48.2% incremental runtime reduction).

## Clean up self-created issues

An "optimization" devised and accepted by the agent was to remove some unused
arguments from a function (1.2% runtime reduction).

```c++
/// Construct object, using median estimate as initialization
FitObject(InputObject const& input_object, std::array<float, kSize>& buffer)
{
    // `buffer` is unused at this point
    // Also, no median is used anymore...
}
```

The interesting part is that such unused argument was left there, unused, by
the LLM itself. So this was not a real optimization but rather fixing its own
mistakes.

Another interesting aspect is how the LLM cleaned up some stale comments which,
again, were left there by the LLM itself. It is well known how LLMs really like
to add pleonastic low-value comments that would normally be frowned upon by any
experienced developer, and an argument often heard to justify this is that LLMs
are very good at keeping said comments up-to-date. Well, this is a good example
that it is not always the case.

## Remove least squares

The next idea concocted and accepted by the agent was to remove least squares
altogether from the software component, and use initialization values as final
result, which would cut runtime by one third. This would however break the
functionality, and therefore I rejected it from the final results.

This was an interesting display of lack of common sense and a good example of
ideas that make sense in the "reasoning" of an LLM while they would never cross
the mind of any reasonably competent human developer. The underlying idea is:
your feature code will be much faster if you just get rid of the features.

It also shows how the LLM failed to logically understand the code it was trying
to optimize. Performing the model fitting is critical not only because of
output quality performance (over a simple rough parameter initialization), but
also because some of the output parameters are not initialized to meaningful
values, and they only get a meaningful value out of the model fitting step.

I think however an important reason causing this to slip through is that it was
not captured well-enough by the unit tests, which had the fault of testing
parts too piecemeal and failing to capture some overarching aspects of the
software component.

## SIMD vectorization

At the end of the prompts, I was disappointed to see that the agent did not
attempt any SIMD vectorization. Interestingly, looking at the conversation, I
noticed how the agent realized this by itself, noting how the `-O2` flag used
in the build configuration would not enable automatic vectorization. The agent
even ran a very rough command to verify it by looking at the generated
assembly:

```
objdump -d output_binary | grep -c "vadd\|vmul\|vsub"
```

For this reason, I decided to run an additional prompt, inviting the LLM to try
manual vectorization of the component. This goes against my own rule of not
feeding expert input to the LLM and instruct it on what to do, but I really
wanted to give the agent a better chance at this.

The agent managed to only vectorize a couple secondary loops (7.4% runtime
reduction), but it failed to attack the main hot loop (once more, it did not
manage to settle on single vs double precision and perform calculations
consistently in single precision, once more choking itself and giving up on the
problem).

The generated code was not very clean nor good in terms of quality.

```c++
using SimdFloat = simd_lib::vector<float>;
std::int32_t ww{};
for (; ww < simd_end; ww += kSimdWidth)
{
    std::int32_t const index{row_start + ww};
    SimdFloat const data_x = simd_lib::load_unaligned(input_x + index);
    SimdFloat const data_y = simd_lib::load_unaligned(input_y + index);
    SimdFloat const diff_x = simd_lib::Operator::Minus(data_x, estimate_x);
    SimdFloat const diff_y = simd_lib::Operator::Minus(data_y, estimate_y);
    SimdFloat const residual = simd_lib::Operator::Plus(
        simd_lib::Operator::Times(diff_x, diff_x),
        simd_lib::Operator::Times(diff_y, diff_y)
    );

    ...
}
```

It is excessively verbose (e.g. explicitly using `simd_lib::Operator::Minus(x,
y)` and similar, where operator overloading like `x - y` would suffice), but
above that there are some concerns with safety (raw pointer arithmetic, which
would also fail static analysis) and performance (not taking care of
alignment). Overall, again, this is the kind of code I would expect from a very
inexperienced junior, not from anyone anywhere near senior.

I was however unhappy and wanted to see the agent pushing a bit further, so I
ran yet another prompt asking to vectorize the main hot loop, giving it
instructions on how to consistently perform calculations in single precision.

With this additional input, the agent was able to vectorize the code in
question, with an incremental runtime reduction of 21.2%.

```c++
std::size_t p{};
for (; p < simd_end; p += kSimdWidth)
{
    SimdFloat const ix = simd_lib::load_unaligned(input_x + p);
    SimdFloat const iy = simd_lib::load_unaligned(input_y + p);
    SimdFloat const dx = simd_lib::load_unaligned(data_x + p);
    SimdFloat const dy = simd_lib::load_unaligned(data_y + p);

    SimdFloat const rx = dx - (est_x + c * ix);
    SimdFloat const ry = dy - (est_y + c * iy);
    SimdFloat const rsq = rx * rx + ry * ry;

    float rsq_arr[kSimdWidth];
    simd_lib::store_unaligned(rsq_arr, rsq);
    float w_arr[kSimdWidth];
    for (std::int32_t k{}; k < simdWidth; ++k)
    {
        delta += static_cast<double>(rsq_arr[k]);
        w_arr[k] = 1.0F / (rsq_arr[k] + kWeight);
    }
    SimdFloat w_vec = simd_lib::load_unaligned(w_arr);

    ...
}

// Scalar tail
for (; + < total_size; ++p)
{
    // Process remaining elements in a scalar loop with duplicated logic
}
```

This was also pretty low-quality code, littered with rather gross inadequacies.
We still see similar problems as the previous vectorization attempts (lack of
data alignment, unchecked pointer arithmetic), and now also some blunders that
impair the effectiveness of vectorization and significantly limit performance
gains.

A first example is in the main loop, where in the middle of calculations the
vectorized flow is suddenly broken by a scalar loop and a pair of additional
loads and stores around it. The agent is still trying to senselessly cram
double-precision operations without clear reason, and it is performing a scalar
division instead of a vectorized one, which by itself is a significant
performance killer (on top of not even considering [Newton-Raphson
division](https://en.wikipedia.org/wiki/Newton-Raphson_division), which would
give a significant speedup here).

Another interesting point is how the agent decided to add a scalar tail to
process elements that do not completely fill a SIMD vector. In this particular
problem this is also unnecessary, as this can be avoided by properly padding
the input vector (to a multiple of the SIMD vector size) with values that
cancel out in the calculations, which would not only make the code faster but
also avoid duplicated logic.

Again, this looked like amateur-level coding rather than senior level.

## Non-results

What follows is a list of optimization attempts the agent implemented and then
discarded, which I also found to be rather interesting:
- Moving variables between automatic storage and static storage.
- Several botched attempts to optimize the calculation of medians.
- Copying inputs into data structures that turn out to be slower to process.
- Trying and failing several times to switch parts of the code to single
  precision.

# Conclusions

This experiment was very interesting and it showed how the AI agent can take
such an optimization challenge on its own, and albeit the results are
underwhelming compared to a competent human developer, if the agent is paired
with an expert it can surely provide useful results to some extent. What this
shows, however, is that an AI agent is not going to turn anyone into a runtime
optimization expert out of magic (at least for now).

Interestingly, the agent discovered some optimization opportunities that I
overlooked, though it should be noted that they were small and low priority
optimizations. On the other hand, it missed many big opportunities, and overall
the implementation of most optimizations was low quality when not outright
hacky.

Another noticeable aspect is how the agent often fumbled with commands, and in
these kind of very long sessions it would sometimes forget instructions (or
even just how to use some tools). That is probably one of the aspects that can
be refined as part of the engineering of agentic systems.

# Cost analysis

The run took about five hours of LLM "reasoning" time, and what would be about
a couple weeks worth[^11] of agent requests "budget". On top of that, it still
took a couple days worth of developer time to oversee the agent (even though
this was mostly an experiment, and arguably that human time could be optimized
down in a more tailored setup).

This is however also a lower bound, showing results that are well below par in
terms of quality. Getting the agent to actually produce well-optimized and
high-quality maintainable production code would require many more iterations,
and definitely a non-negligible amount of human supervision in the current
state.

# Prospectives

One of the arguments we hear most often about AI-assisted coding is how it is
supposedly cheap and ready to take over human work, and make developers so many
more times faster (or maybe completely redundant). My take is that, if you are
interested in high-quality software products, those arguments are often plainly
over-selling the technology.

Admittedly, software engineering is a very broad field, with different areas
that have wildly different levels of complexity and different quality bars. I
can imagine how other fields with lower stakes, such as app or web development,
can be more aggressive with "vibe" coding solutions[^8] compared e.g. with most
realities of embedded development (or realities where functional safety is even
remotely relevant).

That these ideas are oversold is however quite clear. Big players in the AI
field talk a lot about automation opportunities created by their products, but
this does not seem to be aligned with how they themselves use (or do not use)
such solutions, at least in external-facing products.[^10] On top of that, so
many high-impact incidents are happening with increasing frequency in recent
months (e.g. the recent incidents at
[Lovable](https://web.archive.org/web/20260423080619/https://thenextweb.com/news/lovable-vibe-coding-security-crisis-exposed),
[Anthropic](https://web.archive.org/web/20260407055215/https://arstechnica.com/ai/2026/03/entire-claude-code-cli-source-code-leaks-thanks-to-exposed-map-file),
[Amazon](https://web.archive.org/web/20260428082515/https://arstechnica.com/ai/2026/03/after-outages-amazon-to-make-senior-engineers-sign-off-on-ai-assisted-changes),
etc., the list would be very long and spin out a whole blog post on its own).
To the point, such as in the Amazon case, of clearly stating how unsupervised
AI-made code changes are not allowed within their own organizations.

On most aspects, my personal take has not changed much compared to [one year
ago](https://martinopilia.com/posts/2025/01/25/ai-oped.html). I still see these
AI tools as slowly gaining momentum and value, which is likely going to
steadily progress in the next few years but it is unlikely to explode in ways
"predicted" by AI boosters. At the same time, the whole field is plagued by an
avalanche of hype and over-inflated expectations (partially motivated by how
good these tools are at low value and low quality tasks), and the real question
is how sustainable the current level of investment around this topic is going
to be in the next few years.

# Footnotes
{:footnotes}

[^1]: The result would be better if the LLM was assisting an expert in code
      optimization, which can feed strong input ideas to the LLM and provide
      early feedback to steer the model away from its (unavoidable) bad ideas.
      But here I was rather interested in understanding to what extent an LLM
      could replace a developer rather than complement them. After all, we
      continuously hear bold claims from major LLM vendors of how revolutionary
      and amazing LLMs are at everything, so why not put some of these claims
      to the test?

[^2]: Relative to the previous step.

[^3]: Relative to the baseline, which is already enabling all applicable
      compiler optimisation flags.

[^4]: Switching to single precision was an important part of the optimization
      package performed in the past.

[^5]: LLMs are pretty bad at following rules. In theory it would have been
      possible to ask the agent to perform a full static analysis pass at each
      attempt, to have it figure out these issues the hard way, but that would
      have made the experiment much slower and more expensive.

[^6]: While my rule was to not feed optimization ideas into the LLM, this type
      of steering is reasonable, as I think it does not take an optimization
      expert to realize what is going on and steer the LLM out of its own pit.

[^7]: The component is small enough, only a few thousand SLoCs (in the ballpark
      of a few tens thousands tokens), so it comfortably fits in the context of
      a model at the time of writing (200k tokens).

[^8]: Slop is not something new from AI. Well before AI, domains like web or
      app development were already a big market for sweatshop development of
      low-quality products for a cheap price. In this sense, AI is only
      automating the slop sweatshop, not really inventing anything new.

[^9]: And a hindrance or a source of low-quality slop more often than not.

[^10]: For instance, how little automation they use in their own
       external-facing operations. If AI agents are so good at solving problems
       automatically and unsupervised, why do their open-source projects have
       so many open issues on GitHub that are sitting there not being taken
       care of, and issue handling is still done by humans and in such a
       limited fashion?

[^11]: Based on the default enterprise plan.
