---
layout: post
title: Designing a least squares fit confidence estimate
subtitle: But making it run very fast
image: /posts/img/fit_confidence/model_fit.svg
image-license:
  url: https://commons.wikimedia.org/wiki/File:Linear_regression_residuals.svg
  text: "Image: Justinkunimune (CC0 1.0)"
show-avatar: false
mathjax: true
tags: [model fitting, statistical estimation]
---

While working on a project some time back, a friend asked me how to develop an
effective confidence estimate for a model fitting problem such that it could
run very fast in real time on a constrained system. While the question might
sound mundane, I found the specific constraints called for an interesting
solution. This post is a short elaboration of how to construct a good answer.

# Background

[Least squares](https://en.wikipedia.org/wiki/Least_squares) is a well-known
method to fit a model to data by minimising a loss based on the sum of squared
residuals between the model function and the data being fitted. There are
several categories of least squares methods based on the nature of the model
function, with a first broad distinction based on whether it is linear in all
variables or not. Some least squares methods use linearization, weighting of
samples, or iterative refinement of the solution.

The method was first published in the early 19th century but its broad concept,
to some extent, has been understood since the 18th century if not earlier. What
is commonly regarded as the first fully fledged example of least squares
regression is the prediction of
[Ceres](https://en.wikipedia.org/wiki/Ceres_(dwarf_planet))'s orbit by Gauss in
1801,[^1] four years before the first publication of the method by Legendre in
1805 {% cite legendre1805nouvelles %}.[^2]

In their problem, my friend was using
[weighted](https://en.wikipedia.org/wiki/Weighted_least_squares) and
[non-linear](https://en.wikipedia.org/wiki/Non-linear_least_squares) least
squares:

$$
S(\boldsymbol{x}) = \sum_i w_i \left( y_i - f(x_i) \right)^2
$$

They wanted to develop an additional function providing a confidence value
estimating whether the results produced by each run of their algorithm were
trustworthy, expressed as a pseudo-probability scalar with values ranging in
$$[0, 1]$$. In this confidence value they wanted to take the goodness-of-fit
into account.

They had tried several standard approaches based on analysis of the residuals.
Since they were using a relatively large number of samples for the model fit,
however, even a single additional pass over the input vector (or adding more
calculations to the existing pass) was going to be too expensive under their
system's constraints.

# Approach

If I wanted to solve this without adding any more calculations to their kernel,
I needed to construct an estimator based on quantities we already had at hand.

A key observation, at the core of the solution I proposed to them, comes from
theory. We know that the covariance $$\boldsymbol{C}$$ of a least squares
estimator is given by

$$
\boldsymbol{C} = \sigma^2 \boldsymbol{H}^{-1}
$$

where $$H$$ is the Hessian matrix, which in the non-linear case is commonly
approximated from the Jacobian $$\boldsymbol{J}$$ as $$\boldsymbol{J}^\top
\boldsymbol{J}$$, and $$\sigma$$ is the [reduced Chi-squared
statistic](https://en.wikipedia.org/wiki/Reduced_chi-squared_statistic), which
for weighted least squares is given by the inner product of the residuals
$$\boldsymbol{r}$$ with themselves (induced by the weights $$\boldsymbol{W}$$),
i.e. the minimum value of the loss function, scaled by the degrees of freedom
$$\nu$$ as

$$
\sigma^2 = \frac{\boldsymbol{r}^\top \boldsymbol{W} \boldsymbol{r}}{\nu}
$$

Since the covariance matrix encodes information on the dispersion of the fitted
estimator, it can be a good input to our confidence function. And good news, we
are already computing the Hessian matrix as part of the non-linear least
squares calculations, so we get it for free.

In an optimized implementation we are not explicitly computing the value of the
loss function, therefore we cannot afford to compute the value of the reduced
Chi-squared statistic. By ignoring it we are still working with an
approximation of the covariance that is still strongly correlated with the real
covariance.

To compute our approximate covariance we only need to pay the cost of a matrix
inversion and a handful of scalar operations. Or, even better, we can avoid the
matrix inversion altogether, for both cost and numerical stability reasons.[^3]
After all our final goal is not to estimate the covariance but rather the
confidence, which will be inversely related to it.

The next step is to translate our matrix into a scalar quantity. The most
straightforward way is probably to take its determinant, i.e. to work with the
[generalized variance](https://en.wikipedia.org/wiki/Generalized_variance), or
rather its inverse. The generalized variance captures the overall dispersion of
the distribution (or lack thereof), while also accounting for correlations
between parameters (if any).

A much cheaper alternative is however to compute the trace instead. Compared to
the determinant, it has the disadvantage of ignoring correlations (and
therefore it only reflects total marginal variance), but it is much cheaper to
compute and numerically more robust, as it is not affected by small
eigenvalues. The value of the trace can be dominated by a single large
eigenvalue, but that is not a problem for our application as this would still
denote a low confidence scenario (while on the other hand, a determinant
dominated by a very small eigenvalue could "hide" other dimensions with high
uncertainty, which would be undesired).

The final step is to map the trace to a pseudo-probability.[^4] I suggested a
very simple approach, passing the trace $$t$$ to an exponential function
$$e^{-(a t + b)^2}$$ with constant parameters $$a$$ and $$b$$ that are
themselves fit from data, which worked fairly well for their problem despite
its simplicity.

# Conclusions

I liked this small problem and felt it was an interesting example, so even
after a few years it was still lingering in the back of my mind and I decided
to present it here, as I think it can be useful to others.

# References

{% bibliography --cited %}

# Footnotes
{:footnotes}

[^1]: The [Ceres](https://web.archive.org/web/20260112120234/http://ceres-solver.org/)
      solver is named after this fact.

[^2]: Gauss is known for not rushing to publish his results. More extreme
      examples include fundamental results, such as his development of
      non-Euclidean geometry, that he never published.

[^3]: Their problem had a small number of model parameters, so even the
      inversion would have been relatively cheap. But avoiding the explicit
      calculation of a matrix inverse whenever possible is a [general rule of
      thumb](https://web.archive.org/web/20260103171942/https://www.johndcook.com/blog/2010/01/19/dont-invert-that-matrix/)
      in numerical analysis, as it has several benefits in terms of cost and
      numerical stability.

[^4]: This pseudo-probability could then be combined with other domain-specific
      signals that my friend already had at hand and that contributed to the
      overall confidence of their problem, beyond the model fitting part itself.
      But that is very much problem-specific and not relevant to the subject of
      this post.
