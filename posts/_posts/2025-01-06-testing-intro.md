---
layout: post
title: Testing tips for junior developers
subtitle: Or how to save me from repeating the same comments in code reviews
image: /posts/img/testing_intro/bug.svg
image-license:
  url: https://commons.wikimedia.org/wiki/File:Bug3.svg
  text: "Image: Lemonlime (CC0 1.0)"
show-avatar: false
mathjax: true
tags: [googletest, googlemock, testing, unit testing, C++]
---

Software testing is a fundamental aspect of any serious engineering effort, but
at the same time it is such a young discipline. Importance of testing has been
known in the industry for decades from a theoretical point of view, yet it took
it a very long time to catch up in practice and become an integral part of
development cycles. To get some perspective, even major software companies
started embracing pervasive automated testing policies only in the mid 2000s {%
cite sweag2020testing %}.

Besides the young age of the discipline, testing competence is also penalized
by being rarely taught within education programs. The average computer science
(or adjacent) graduate has probably never used a test framework in their
education, and more importantly has never learned the importance of testing,
let alone its principles, caveats, and tricks of the trade. When such young
professional figures join the industry, they are obviously put at a
disadvantage. Nevertheless, a lot of progress has happened in the industry,
especially in the last twenty years, and there is hope that higher education
will catch up with it.

The aim of this post is not to be a treaty on software testing, as many good
essays are already published and more extensive and informative coverage on the
subject can be readily found elsewhere. It is instead meant as a collection of
tips and comments I often found myself repeating in code reviews, with the hope
that they can be useful to the more junior readers to avoid repeating the same
pitfalls. As such, it is a fairly unstructured collection, and presence (or
absence) of topics or their order of presentation has no intended relation with
their relative importance. Only some topics are covered in this post, and more
topics might follow in future posts.

# Test behaviour, not implementation

This is one of the most basic rules of testing. Yet I often see this basic
principle being violated in various ways, such as by mirroring non-public
behaviour in the test code (i.e. writing tests based on knowledge of the
implementation that is not supposed to be part of its public API), misusing
mocks to manipulate internals of the implementation, befriending the production
code with the test fixture to access non public members from the test
cases,[^8] and the likes.

Tests should not be tied to implementation details, for at least two main
reasons.

Firstly, reflecting the implementation in the tests injects a strong bias
towards the behaviour of the implementation itself, which might differ from the
expected behaviour. If the implementation is defective, the same bugs might be
reflected in the tests and remain undetected.

In an ideal world, tests would be implemented by different people other the
ones that work on the feature implementation, and would be written
independently than the feature itself, i.e. without looking at its
implementation (possibly even before the feature itself is implemented). Not
many companies can afford this in practice from a logistical standpoint though,
and also having the same developer work on both feature and corresponding tests
usually speeds up the writing process.

Another reason is that tests coupled with implementation details are fragile,
and they can break when the implementation changes, even if the interface and
behaviour are unchanged. This creates additional maintenance cost, and at the
same time it slows development down.

Good tests should fail when the behaviour of the feature does not meet
expectations, and they are expected to break if behaviour is changed or if the
interface to the tested feature is changed. However, tests that break due to
internal changes that should be transparent to the user are expensive and
annoying to deal with, and are a symptom of bad test design.

# Write atomic test cases

Atomicity is one of the most important properties of good test cases. Each test
case should be limited to one behavioural aspect of one unit, on one input
datum.

The following is not good:

```c++
TEST(MyClass, Test)
{
    MyClass object{};

    ASSERT_EQ(object.foo(0.0), Foo{0.0});
    ASSERT_EQ(object.foo(1.0), Foo{1.0});
    ASSERT_EQ(object.bar(), Bar{});
}
```

Mixing up different aspect (or even different units) in the same test case
makes tests more complex than necessary, which makes them more error-prone,
increasing the cost due to bugs, and also harder to read and modify (i.e. more
expensive to maintain). It also makes test reports less granular: when a
Frankenstein test covering many behaviours fails, it is not obviously clear
which aspects of the software are broken and which ones are not.

Even just testing different data points in the same test case poses a risk.
Re-using the same scope, as opposed to test each data point in a clean fixture,
increases the risk of bugs or mistakes in the test due to objects being in a
state that is different than intended (after being modified by previous
operations). This can easily hide bugs.

The following is better:

```c++
class MyClassTest : public ::testing::Test
{
 protected:
    MyClass _object{};
};

class MyClassTestFoo : public MyClassTest,
                       public ::testing::WithParamInterface<double>
{};

TEST_P(MyClassTestFoo, GetFoo)
{
    ASSERT_EQ(_object.foo(GetParam()), Foo{GetParam()});
}

INSTANTIATE_TEST_SUITE_P(MyClassTestFoo, MyClassTestFoo, ::testing::Values(0.0, 1.0));

TEST_F(MyClassTest, GetBar)
{
    ASSERT_EQ(_object.bar(), Bar{});
}
```

Now we have different tests for each method, and for each data point when
testing the same method multiple times. In this small example it might look
like an overkill, but in my experience it is not. Even in simpler cases, the
benefits easily outweight the need to write a few more lines of code, and the
structure easily and better scales when adding more test cases is unavoidably
needed.

Whenever I stumble upon tests written without respecting atomicity, I find bugs
in them more often than not.

# Write for readability

Readability of tests is one of the most important aspects, yet it is one of the
most easily underrated by test authors. When it comes to test cases,
readability has two faces: readability of the test script, and readability of
its output. This section argues over the former.

Most software projects these days lack written requirements (and often also,
unfortunately, they lack proper documentation), in which case test scripts
often double their role as documentation for the intended behaviour of the
product. For this reason, it is very important to make it clear what behaviour
is being tested and why.[^9]

Way too many times I had to deal with test cases composed of excessively
lengthy and unstructured blobs of code, where it was not even clear what was
under test to begin with. For example, let assume we are testing an odometer,
and I get to review a test case written like this:

```c++
TEST_F(Odometer, TestOdometry)
{
    double x{};
    double y{};
    double z{};
    double vx{0.7};
    double vy{0.5};
    double vz{};
    double elapsed{};
    double const t{0.02}

    // do some acceleration
    while (elapsed < 1.0)
    {
        double const ax{0.5};
        double const ay{};
        double const az{0.1};
        x += vx * t + 0.5 * ax * t * t;
        y += vy * t + 0.5 * ay * t * t;
        z += vz * t + 0.5 * az * t * t;
        vx += ax * t;
        vy += ay * t;
        vz += az * t;
        elapsed += t;

        _odometer.step(Input{mps(vx), mps(vy), mps(vz)});
    }

    ASSERT_EQ(_odometer.state().position.x().meters().value(), 0.95);
    ASSERT_EQ(_odometer.state().position.y().meters().value(), 0.5);
    ASSERT_EQ(_odometer.state().position.z().meters().value(), 0.05);

    // do some coasting
    while (elapsed < 2.0)
    {
        x += vx * t;
        y += vy * t;
        z += vz * t;
        elapsed += t;

        _odometer.step(Input{mps(vx), mps(vy), mps(vz)});
    }

    ASSERT_EQ(_odometer.state().position.x().meters().value(), 2.15);
    ASSERT_EQ(_odometer.state().position.y().meters().value(), 1.0);
    ASSERT_EQ(_odometer.state().position.z().meters().value(), 0.15);
}
```

This is hard to follow and easy to get wrong.[^7] In my opinion, this test is
way longer and more complex than it should be acceptable. Yet in practice it is
not uncommon to see test code that is significantly worse than this.

Besides the obvious downside of creating an unnecessary spike in maintenance
cost, such kind of test is very dangerous because, when something goes wrong,
it becomes hard to understand whether the issue lies within the product or
within the test itself.

I warmly recommend following a handful rules to write readable tests:
* Make your names as descriptive as possible. Often test frameworks use two
  levels of naming (fixture and test cases), in which case you typically want
  the fixture to describe what unit (class, method, or function) is being
  tested, and the test case to concisely but clearly describe what behavioural
  aspect it covers (you will normally have many test cases for each unit).
* Keep the size of test cases small, in the ballpark of a dozen statements or
  so. That sounds like a very small number and you might think it is too
  strict. Well, in my experience it is not. Any piece of non-trivial logic
  (i.e. more than a handful statements) in the initialization or verification
  parts should be moved into self-contained, clearly written, and well-named
  auxiliary classes or functions.
* Use a good pattern to create a clear separation across initialization logic,
  action under test,[^5] and verification of the results. The
  [Arrange-Act-Assert (AAA)
  pattern](https://automationpanda.com/2020/07/07/arrange-act-assert-a-pattern-for-writing-good-tests/)
  is usually a good one to follow as a rule of thumb.

If I had to have a stab at this myself, it would probably look more like this:

```c++
TEST_F(OdometerTest, FinalPositionWhenAcceleratingAndThenCoasting)
{
    // Arrange
    auto const input_generator = InputGenerator(2.0_s, 50.0_hz)
        .setInitialVelocity(Velocity{0.7_mps, 0.5_mps, 0.0_mps}))
        .addAcceleration(AccelerationBuilder{}
                            .start(0.0_s)
                            .end(1.0_s)
                            .magnitude(XYZ{0.5_mps2, 0.0_mps2, 0.1_mps2}))
    auto const odometer = OdometerFactory{_resource_pool}.makeStaticOdometer(input_generator.frequency());

    // Act
    while (auto const input = input_generator())
    {
        auto status = odometer.step(*input);

        ASSERT_EQ(status, Odometer::Status::Ok);  // Coherence check
    }

    // Assert
    auto const& state = odometer.getState();
    EXPECT_THAT(state.position.x(), IsApprox(2.15_m));
    EXPECT_THAT(state.position.y(), IsApprox(1.0_m));
    EXPECT_THAT(state.position.z(), IsApprox(0.15_m));
}
```

I defined generators and builders for the various test inputs, custom matchers
for robust numerical testing, and created three distinct sections for the AAA
pattern. I limit the assertions to one scenario (see the section about
atomicity above), different scenarios should get their own self-contained test
case.

Out of context this might look like an overkill. But consider that, in order to
properly test your odometer, this test alone is not enough and dozens more of
similar tests (at best) will be needed. That is where having good abstract test
machinery suddenly gives a lot of value.[^6]

# Write for readability (of the test output)

The importance of producing clear and easy to troubleshoot test output sounds
obvious, yet in my experience it is so often missed by test authors.

Take the following as an (oversimplified) example:

```c++
void assertResult(double const result, double const input)
{
    auto const expected = computeExpected(input);
    EXPECT_EQ(result, expected);
}

TEST(MyFunction, Test)
{
    assertResult(myFunction(1.0), 1.0);
    assertResult(myFunction(2.0), 2.0);
    assertResult(myFunction(3.0), 3.0);

    for (int x{5}, x < 10; ++x)
    {
         assertResult(myFunction(static_cast<double>(x));)
    }
}
```

This test case has some obvious maintainability issues in the implementation of
the test script itself (see the sections about atomicity and readability
above), but it will also fail to produce understandable test output.

The catch is that the `EXPECT_EQ` macro is wrapped by the `assertResult()`
function, which is called multiple times. Therefore, `EXPECT_EQ` will print
to the test output information only related to its position inside
`assertResult()`, and if a failure happens, it will not be clear which call of
`assertResult()` caused it.

Some people will argue that this is not a problem, as all you need to
troubleshoot a problem is to fire up a debugger and run the test under it. That
is to me symptom of a problematic mindset, and debuggers are not the right tool
for this. A debugger is an incredibly powerful and useful tool, but in most
cases it is an overkill. Needing to run a debugger to understand a test failure
is not just a waste of time that could be avoided by writing good tests, but it
is also not always feasible (some tests might be running in some remote and
inaccessible environment that cannot be reproduced locally).

The proper solution is to use the right tools offered by your test framework
(such as fixtures, parametrizations, etc.) to write atomic and self-contained
tests that always provide complete tracing information.

If you need to put assertions in loops, or other scopes that might hide
traceability, use proper tracing tools to ensure that information is present.
Specifically to GTest, `SCOPED_TRACE` is always a handy tool, but don't forget
that it is possible to add tracing information by applying `operator<<` to the
value expanded by the various assert/expect macros.

```c++
TEST(MyClass, Test)
{
   // ...

   for (int i{}; i < 10; ++i)
   {
       SCOPED_TRACE("i = " + ::testing::PrintToString(i));

       EXPECT_EQ(...) << "Extra info here";
   }
}
```

# Learn to understand coverage

Code coverage is both a good tool and a useless metric. It is a good tool in
the sense that it helps spotting parts of the program that are not being
tested. It is a useless metric because having a piece of code being covered
does not mean that the behaviour of that piece of code is being tested, it
merely means it is being executed in a test suite. This makes high coverage
necessary, but not sufficient.

Sadly, I personally had to work in multiple occasions on projects where
developers where adding functionally useless tests solely for the purpose of
boosting coverage values, while the tests themselves were not verifying any
functional behaviour.

When testing your product, reason more in terms of covering the expected
behaviour, rather than covering lines or branches. If you have requirements for
it, they can be a useful input for this.

Pay attention to your changes. Did you make a change that altered existing
behaviour but required no updates to your tests? Then there is a good chance
that such part of your product is not actually being tested, no matter what
your coverage metrics say.

# Use good oracles

When working with [functional
programming](https://en.wikipedia.org/wiki/Functional_programming),[^1] coming up
with the right [test oracles](https://en.wikipedia.org/wiki/Test_oracle) is one of
the best ways to make your tests simpler, stronger, and easier to maintain.

A test oracle is an entity that provides the expected results for a given set
of inputs, which can then be compared with the tested program output to verify
its correctness.

Consider a function $$f$$ that maps values from domain $$A$$ to domain $$B$$

$$
\begin{align*}
f(x): ~ &A \to B \\
        &x \mapsto y
\end{align*}
$$

One of the easiest ways to test such function is to use an oracle $$g$$
implementing the same mapping

$$
\begin{align*}
g(x): ~ &A \to B \\
        &x \mapsto y
\end{align*}
$$

and test that $$f(x) = g(x)$$.

If you already have some other function at hand that implements the same
mapping (and that can you trust), then you have an easy solution at hand.[^2]
If not, you might be able to implement your own oracle.

As a general rule, it is better to avoid mirroring the implementation of your
feature in your oracle. Way too many times I had to comment in code reviews,
pointing out how people were copypasting their feature code into a test file
straight away. Besides obvious issues with duplication that hinder
maintainability, such habit  makes it very likely that any defects and bugs in
your feature code will also be present in your oracle, therefore hiding them
from the tests. It also mirrors the complexity of your feature in your test
code, which is undesirable, as test code should strive to be as simple as
possible.

Try instead using a different method or algorithm to implement the test oracle.
Test code has generally less constraints compared to production, and that
includes runtime performance, therefore you might be able to use a simpler
algorithm as a test oracle to compare against (that maybe is too slow to be
used in production).[^3] Using a simpler algorithm also means your test code
will be simple, which is itself a win by itself.

If possible, however, I find the best approach is to use an inverse oracle.
In this case, instead of directly testing $$f(x) = g(x)$$, the oracle
implements the [inverse](https://en.wikipedia.org/wiki/Inverse_function) of
$$f$$

$$
\begin{align*}
g(y): ~ &B \to A \\
        &y \mapsto x
\end{align*}
$$

and the test verifies that $$g(f(x)) = x$$.

When you are implementing the oracle yourself, this is a strong testing
approach as it makes it easier to write oracles that are independent from the
tested feature code. It is not always applicable however, because not all
functions are invertible, and some invertible functions might actually be very
hard to invert in practice.

# Pay attention to speed

Speed of tests is an important but often neglected aspect. The primary reason
is that slow tests simply do not scale. One might naïvely think that having a
test case taking one second is not a big deal. Now picture in your head a
thousand test cases taking one second, and suddenly your unit test suite takes
half an hour to run. And a thousand test cases is a very small number, it is
barely enough to cover a very small (if not toy-sized) project.

You want to be able to work with a fast edit-build-test loop locally, so slow
tests would directly affect your own tight local development loop, and on top
of that they would slow down (to an even larger extent) your remote execution
and CI pipelines.
A good introduction to the subject is provided by Michael Feathers in its
well-known *Working effectively with legacy code* {% cite feathers2004working
%}.

You want to be able to run at least several hundred test cases in a fraction of
a second, which means that, as a rule of thumb, the runtime of your individual
unit tests should be in the ballpark of milliseconds. Avoid remote resources
(that are also a liability when it comes to robustness, which will be discussed
separately) and avoid using the file system.

Sometimes, slower tests (possibly involving complex or slow resources) are
necessary. Keep in mind that such kind of tests should be a dedicated tool for
specific scenarios (e.g. integration testing), it should not be the norm for
unit tests. If possible, separate your expensive tests from regular unit tests
(e.g. using tags that can be filtered upon, running them in dedicated
pipelines, etc.).[^4]

<!--
# Write for readability (of the test output)
# Write deterministic tests
# Harness randomness (RapidCheck)
# Get familiar with the GTest API
# Avoid putting asserts outside tests
# Use matchers
# Make your types printable
# Importance of test output
# Testability as design quality
# Use mocks carefully
-->

# References

{% bibliography --cited %}

# Footnotes
{:footnotes}

[^1]: Which you should if possible, because functional programming allows to
      avoid many footguns that come with stateful program entities, making your
      programs easier to reason about and less error-prone. Note that
      functional programming is a paradigm and it has nothing to do with the
      choice of language (albeit some languages make it easier to do functional
      programming with them).

[^2]: You might be wondering why you need to implement your own feature then,
      and not just use the oracle in production. There might be a multitude of
      different reasons:
      * The oracle is too slow to meet performance requirements in production.
      * The oracle does not fulfill some requirements, related to safety,
        licensing, etc.
      * The oracle lacks some aspects that you need in production. For
        instance, assume you are working on a C++14 project and you need a
        `constexpr` sort function. You cannot use `std::sort` (as `std::sort`
        is not `constexpr` before C++17), but you can test the output of your
        implementation against the output of `std::sort`.

[^3]: Though you should be careful to stay within reasonable bounds, and make
      sure you set acceptable goals. Otherwise, your test and integration
      routine and machinery will get slow, negatively affecting productivity as
      a whole.

[^4]: *Software engineering at Google* provides an example of how tests can be
      classified into different "sizes" and handled with different criteria and
      rules based on that {% cite sweag2020testing %}.

[^5]: Which should be only one, see section above about atomicity of test cases.

[^6]: Additionally, I do not pass around dimensional values in `double`
    variables, too easy to get them mixed up. The type system is our friend,
    and strong typing prevents possible issues. Here [user-defined
    literals](https://en.cppreference.com/w/cpp/language/user_literal) are
    used, but it is only one of many possible ways of doing this.

[^7]: Honestly I would not be surprised if something in it was actually wrong.
    This is not a real example, it is just something I concocted on the spot as
    an illustrative example, without even testing it. Which further reinforces
    the point I am trying to make.

[^8]: This one sounds flat-out crazy to me, yet I have seen it several times in
    the wild, and I had to review such kind of test code myself.

[^9]: Answering the "why" is important. As for the "how", that should not be
    redundantly spelled out in comments, and should be self-evident by
    well-written code. But explanation of the "why" should not be left to the
    implementation, and should be made clear by the author. This ensures that
    the intended behaviour is understandable even in the unavoidable cases when
    the test script itself contains mistakes (or otherwise, said mistakes would
    be implicitly promoted as "intended behaviour").
