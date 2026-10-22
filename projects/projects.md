---
layout: page
title: Projects
subtitle:
css:
    - /css/tiled_layout.css
---

What follows is a selection of some of my open source projects.

{% tiles %}

{% tile pico-ethernet, https://github.com/m-pilia/pico-ethernet %}
<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/pico-ethernet.jpg" markdown="1"/>
</div>
Fully functional full-duplex 10BASE-T Ethernet NIC built on top of a Raspberry
Pi Pico 2.
{% endtile %}

{% tile cujpegxl, https://github.com/m-pilia/cujpegxl %}
<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/cujpegxl.svg" markdown="1"/>
</div>
CUDA-accelerated JPEG XL encoder.
{% endtile %}

{% tile dazelisk, https://github.com/m-pilia/dazelisk %}
<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/dazelisk.svg" markdown="1"/>
</div>
Containerized bazelisk wrapper.
{% endtile %}

{% tile Facturization, https://github.com/m-pilia/facturization %}
<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/facturization.png" markdown="1"/>
</div>
High-quality PDF invoice generator from a YAML specification.
{% endtile %}

{% tile Disptools, https://github.com/m-pilia/disptools %}
<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/disptools.png" markdown="1"/>
</div>
A high-performance C and CUDA library with Python bindings implementing a
research toolkit to generate and manipulate displacement fields with known
volume changes.
{% endtile %}

{% tile vim-ccls, https://github.com/m-pilia/vim-ccls %}
<div class="center-block"
     style="width: 80%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/vim-ccls.png" markdown="1"/>
</div>
Vim/Neovim plugin to integrate extended features of the ccls language server.
{% endtile %}

{% tile vim-yggdrasil, https://github.com/m-pilia/vim-yggdrasil %}
```viml
call yggdrasil#tree#new(s:provider)
```
Vim/Neovim library plugin to create tree views.
{% endtile %}

{% tile Ambient noise, https://github.com/m-pilia/plasma-applet-ambientnoise %}
<div class="center-block"
     style="width: 80%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/ambient_noise.png" markdown="1"/>
</div>
KDE Plasma applet to play an ambient noise mix.
{% endtile %}

{% tile vim-mediawiki, https://github.com/m-pilia/vim-mediawiki %}
<div class="center-block"
     style="width: 80%; text-align: center; font-size: 80%;">
    <img src="/projects/img/previews/vim-mediawiki.png" markdown="1"/>
</div>
Vim/Neovim plugin to edit MediaWiki pages.
{% endtile %}

{% tile volume-raycasting, https://github.com/m-pilia/volume-raycasting %}
<div class="center-block"
     style="width: 80%; text-align: center; font-size: 80%;">
    <img src="/posts/img/raycaster/raycasting_coord.svg" markdown="1"/>
</div>
GPU-accelerated single pass raycaster.
{% endtile %}

{% endtiles %}
