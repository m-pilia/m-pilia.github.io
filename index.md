---
layout: page
title: Martino's page
subtitle:
use-site-title: true
css:
    - /css/tiled_layout.css
---

I am a mathematician and software engineer with strong experience in embedded
development and signal processing (especially computer vision), designing and
implementing modern and robust solutions.

I work primarily on real-time and safety-critical embedded systems and have
contributed to the development of several cool projects that ended up being
innovative world-class products, for example the computer vision system
enabling hands-free autonomous driving on the Mercedes Drive Pilot, the
anti-theft system protecting Bosch e-bikes, and a video stabilization solution
used under the hood by around 900 million Android smartphones.

While most of the technical content in my day job is bound to confidentiality,
on this site you can find more about my side projects and open source
contributions.

I am an enthusiast [Arch Linux](https://www.archlinux.org/),
[KDE](https://www.kde.org/), and [vim](http://www.vim.org/) user. You might
have unknowingly stumbled upon (or maybe even used) some of my open source
contributions to those three open source ecosystems.

{% tiles %}

{% tile , /aboutme , tile-center %}
### About me
{% endtile %}

{% tile , /projects/projects , tile-center %}
### Projects
{% endtile %}

{% tile , /posts , tile-center %}
### Blog
{% endtile %}

{% tile, /links , tile-center %}
### Links
{% endtile %}

{% endtiles %}
