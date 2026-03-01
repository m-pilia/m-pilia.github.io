---
layout: post
title: Diagnosing a compiler bug
subtitle: When you have eliminated the impossible...
image: /posts/img/compiler_bug/compiler_bug.png
image-license:
  text: "Image: Own work (CC-BY-SA 4.0)"
show-avatar: false
mathjax: true
tags: [C++, compiler, bug]
---

This post is about a software issue I troubleshot some time ago. What made it
interesting is how it turned out not to be a bug in the product, but rather in
the C++ compiler used to generate the binary.

In all of it, what surprised me the most is how quick and easy it was to narrow
down and diagnose the problem. One might assume that bugs caused by incorrect
machine code generation are tricky and particularly difficult to deal with, but
it turns out that following best practices and heavily investing in software
quality can make them simpler than one thinks. For this reason, I saw this as
an instructive example and a good talking point about codebase robustness.

# Background

The story started when I received a request to look at a reported issue
involving the behaviour of a software feature. I was not a maintainer of said
feature, but I am knowledgeable about non-trivial C++ subtleties and I also
have a solid math background, so I assume that explains why the problem ended
up on my desk. The feature had been around for a while but apparently it broke
only when running it on a new hardware version.

Executing test suites both on development and target hardware showed no traces
of the problem and, as usual, convincing the customer to produce logs has been
by far the slowest and hardest part of the troubleshooting.

Once I got a hold of logs including inputs needed to reproduce the issue, I saw
no trace of the problem on the development platform. That was odd. Since the
problem was reported by the customer when switching to a new hardware platform,
the next obvious step was to get hold of a hardware rig for that platform. And
then, when running on it, I could finally see the problem for myself.

# Software narrow-down

I quickly realized I had an interesting problem at hand, because the software
was behaving differently across platforms. Moreover, the problem would only
manifest itself when running an optimized build, but not on a debug build.[^1]

The next step was to narrow down the issue to a specific part of the code. This
was actually quick and surprisingly straightforward to do. I knew the problem
originated from a specific system component whose source code was around eight
thousand lines of C++, and looking at the API entry point and the flow of
inputs I could quickly trace this down to a single misbehaving line of code.

```c++
auto const result_matrix = identity_matrix + (some_scalar * some_matrix);
```

The culprit statement was performing a pretty mundane operation but for some
reason, on the failing target platform and system, it was always incorrectly
producing an identity matrix, regardless of the inputs, as if the right-hand
side term of the addition was not there. Definitely not what it should be
doing.

Thankfully I had access to the code of the linear algebra library used there,
which allowed me to dig further and explain how the scalar-matrix product
always ended up being an (incorrectly) zero-filled matrix. Looking into how it
was implemented, I found where the calculations broke, and it was inside a
capturing lambda.

```c++
[op, x](...) {...}
```

For some reason, the value of the `x` capture variable (captured by value)
turned into uninitialized garbage inside the lambda and, interestingly,
changing to a capture by reference would make the problem disappear.

# Unravelling the mystery

What I was observing was definitely breaking the rules of the language. The
fact that it only manifested in optimized builds was also a tell, but not
necessarily proof of anything. The problem with a language such as C++ is the
large room for [undefined
behaviour](https://en.wikipedia.org/wiki/Undefined_behavior) within the
specification of the language itself. Undefined behaviour can easily produce
hard-to-explain results, and can often produce differing behaviours depending
on the optimization level in use.

I had, however, run different static analysers, sanitisers, and
[Valgrind](https://en.wikipedia.org/wiki/Valgrind), and all came back clean.
You generally cannot easily prove the absence of undefined behaviour in a
complex piece of software, but this was definitely strong evidence that
something else was going on and it was not a problem with the C++ code. If the
cause was "simply" an invalid pointer, good chance the sanitisers or Valgrind
would have caught it.

Comparing the assembly emitted for that function between the debug and
optimized builds showed a number of missing store instructions, seemingly
leaving the capture variable uninitialized. This pointed more and more towards
a compiler issue.

For me, compiler bugs are usually a last resort explanation, since the compiler
generally tends to be the most- and best-tested link of the software
development toolchain. And, one might assume, even more so when talking about a
safety-certified compiler (such as in this case).[^2] But, as the well-known
Sherlock Holmes quote goes, "when you have eliminated the impossible, whatever
remains, however improbable, must be the truth" {% cite doyle1890sign %}.

I handed over my assessment of the problem to a core team, so that it could be
reported to the vendor, and indeed it turned out to be caused by a bug in the
[dead store](https://en.wikipedia.org/wiki/Dead_store) elimination performed by
the compiler.

One might wonder why such a problem was breaking just a very specific feature,
instead of wrecking widespread havoc. The reason is that the bug manifested
itself only on sufficiently large capture variables (significantly larger than
a typical 64-bit numeric or pointer type). This feature was indeed using a very
large custom arithmetic type not used anywhere else in the product. Typically,
large types would not be captured by value, and it is also relatively uncommon
for linear algebra libraries to be instantiated with weird user-defined types
in place of fundamental numeric types,[^3] thus explaining how such bug might
have escaped testing by both the compiler vendor and the linear algebra
library developers.

# Take home

I found this investigation to be an interesting and educational experience. It
was not the first time I hit bugs in compilers or other elements of the
software toolchain, but the previous compiler bugs I dealt with were usually
much more straightforward, as they typically involved the compiler straight up
refusing to accept valid code.

The whole troubleshooting took only about a couple of hours of my time, which
was surprisingly quick, and it did not require me to use a debugger at all.[^4]
What made this so easy was having all the right tools already in place. When
you work on a high-quality codebase, troubleshooting issues, even seemingly
exotic and complicated ones, becomes much simpler.

To make your life more convenient and simplify dealing with complex bugs (or,
more often, avoid a lot of the bugs to begin with):
- Make sure you have tests. High-quality tests, extensively verifying
  behaviour, testing negative examples, domain boundaries,
  [fuzzing](https://en.wikipedia.org/wiki/Fuzzing), and property-based testing
  on randomized inputs.
- Make sure to run your tests on all platforms.[^5]
- Have automated builds with multiple different compilers. Enable all warnings,
  and treat warnings as errors.
- Always have an automated sanitiser build where you run your tests under
  sanitisers and Valgrind or similar.
- Always have an automated static analysis build (better if you can use a
  couple of different static analysers).
- Make sure you have a high assertion density.
- Make sure you can enable debug assertions in optimized production builds.

# References

{% bibliography --cited %}


# Footnotes
{:footnotes}

[^1]: An important downside of working with optimized builds is that, when
      compared to debug builds, they have a much smaller set of assertions
      enabled (if any are enabled at all).

[^2]: Though, to be fair, safety certifications are mostly just paperwork. A
      niche compiler with a tiny user base is hardly going to be "safer" in
      practice than a mainstream compiler with orders of magnitude more eyes,
      tests, and users on it.

[^3]: But it should not be unreasonable.

[^4]: Debuggers are powerful tools. But I generally find a debugger to be a
      last resort tool, and "needing" a debugger is usually a symptom of
      missing steps that should be baked and automated in your development
      flow. A debugger can make you quick at diagnosing some issues, but even
      quicker is to not even have to use it to begin with.

[^5]: I would argue this was the main issue that let the fault slip through,
      as this new platform was not sufficiently tested yet.
