---
layout: page
title: Martino's page
subtitle:
use-site-title: true
css:
    - /css/tiled_layout.css
---

{% tiles %}

{% tile, /consulting , tile-center %}
### Consulting
{% endtile %}

{% tile , /posts , tile-center %}
### Blog
{% endtile %}

{% tile , /projects/projects , tile-center %}
### Projects
{% endtile %}

{% tile , /aboutme , tile-center %}
### About me
{% endtile %}

{% endtiles %}

I am a mathematician and software engineer working on research and development
of embedded systems. This website brings together my professional activity,
research work, personal projects, and technical writing on the ideas and
experiments that interest me.

I work primarily on real-time systems, including safety-critical applications.
I have long-standing experience with modern C++ design with a deep command of
language semantics, compiler behaviour, zero-cost abstractions,
high-performance optimizations, and advanced design techniques that take
advantage of modern language features to increase software robustness and
maintainability.

I am experienced in bringing up Bazel projects, either from scratch or as
migrations from legacy build systems (like CMake, Make, or custom systems),
with focus on hermeticity and scalability to make builds fast, deterministic,
and reliable even in large and complex projects.

I contributed to projects like the computer vision system enabling hands-free
autonomous driving on the Mercedes Drive Pilot, the anti-theft system
protecting Bosch e-bikes, and a video stabilization solution used under the
hood by around 900 million Android smartphones.

While most of the technical content of my work is bound to confidentiality, on
this site you can find more about general methods or other interesting public
aspects, as well as my side projects and open source contributions.

I am an enthusiastic [Arch Linux](https://www.archlinux.org/),
[KDE](https://www.kde.org/), and [vim](http://www.vim.org/) user. You might
have unknowingly stumbled upon (or maybe even used) some of my open source
contributions to those three open source ecosystems.
