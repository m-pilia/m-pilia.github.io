---
layout: page
title: About me
subtitle:
css:
    - /css/timeline.css
---

{% timeline
id: aboutme-timeline
categories:
    academia:
        color: "#66CCFF"
        icon: /img/fontawesome/graduation-cap.svg
    project:
        color: "#FFCC66"
        icon: /img/fontawesome/code.svg
    life:
        color: "#99FF99"
        icon: /img/fontawesome/house-chimney.svg
    work:
        color: "#FF9999"
        icon: /img/fontawesome/briefcase.svg
%}

{% event life, January 2022 %}
I moved back to Uppsala, Sweden.
{% endevent %}

{% event academia, Februrary 2021 %}
I co-authored the paper *[Faster dense deformable image registration by utilizing
both CPU and GPU](https://doi.org/10.1117/1.JMI.8.1.014002)*.
{% endevent %}

{% event work, January 2020 %}
I started working at Bosch.

I contributed to the development of the Bosch ConnectModule, a hardware
component of the Bosch E-bike System providing geolocation, anti-theft, and IoT
features to e-bikes.

I primarily contributed to the design and implementation of the embedded
network communication stack and of the embedded resource management.
{% endevent %}

{% event life, January 2020 %}
I moved to Lund, Sweden.
{% endevent %}

{% event project, May 2020 %}
I implemented support for gocryptfs backend in KDE Plasma Vault
[[1]](https://cukic.co/2020/06/01/plasma-vaults-and-gocryptfs/).
{% endevent %}

{% event academia, December 2020 %}
I co-authored the paper *[Recent advances in large scale whole body MRI image
analysis: Imiomics](https://doi.org/10.1145/3427423.3427465)*.
{% endevent %}

{% event academia, February 2020 %}
I released a [technical report](https://github.com/m-pilia/tau-report) on large
scale indoor simultaneous location and mapping (SLAM) solutions based on
research work I performed at Tampere University.
{% endevent %}

{% event project, December 2019 %}
I released [colmap-docker](https://github.com/m-pilia/vim-ccls), a Docker
container to run the [Colmap](https://colmap.github.io/) structure-from-motion
toolbox in a portable manner.
{% endevent %}

{% event project, October 2019 %}
Initial release of [vim-mediawiki](https://github.com/m-pilia/vim-mediawiki), a
plugin to edit MediaWiki pages in vim/Neovim.
{% endevent %}

{% event academia, October 2019 %}
Published the paper *[Average volume reference space for large scale
registration of whole-body magnetic resonance
images](https://doi.org/10.1371/journal.pone.0222700)*.

An overview of the research work is summarized in [a blog
post](/posts/2019/11/17/jacobian-registration.html).
{% endevent %}

{% event project, May 2019 %}
Initial release of [vim-yggdrasil](https://github.com/m-pilia/vim-yggdrasil), a
library plugin to create tree views in vim/Neovim.

Initially developed as a reusable component for my
[vim-ccls](https://github.com/m-pilia/vim-ccls) project, has later been adopted
by the popular [vim-lsp](https://github.com/prabirshrestha/vim-lsp) project
[[1]](https://github.com/prabirshrestha/vim-lsp/blob/24d9f18bca370d7539079dcbea1fe13d0ae1dc8f/autoload/lsp/utils/tree.vim)
and has been source of inspiration for similar plugins (like
[ccls.nvim](https://github.com/ranjithshegde/ccls.nvim), that implemented a Lua
port of vim-yggdrasil).
{% endevent %}

{% event project, May 2019 %}
Initial release of [vim-pkgbuild](https://github.com/m-pilia/vim-pkgbuild), a
plugin to edit PKGBUILD files on vim/Neovim.
{% endevent %}

{% event project, March 2019 %}
Initial release of [vim-ccls](https://github.com/m-pilia/vim-ccls),
a plugin to integrate extended ccls language server features in vim/Neovim.
{% endevent %}

{% event work, December 2018 %}
I started working at Veoneer.

I contributed to the development of SVS4, including the design and
implementation of new stereo camera calibration algorithms and of some object
detection algorithms.

My contributions ended up in several consumer car models, including the Mercedes
EQS Drive Pilot
[[1]](https://www.veoneer.com/en/press/veoneer-radar-and-stereovision-mercedes-eqs-hands-self-driving-tech-1907213),
first customer vehicle in the world to deliver a certified Level 3 (hands-off)
self-driving system
[[2]](https://arstechnica.com/cars/2021/12/mercedes-benz-gets-worlds-first-approval-for-automated-driving-system/).
{% endevent %}

{% event life, December 2018 %}
I moved to Linköping, Sweden.
{% endevent %}

{% event project, July-October 2018 %}
Contributed to the development of [deform](https://github.com/simeks/deform), a
then state-of-the-art deformable image registration library and toolkit.
{% endevent %}

{% event project, September 2018 %}
I implemented a [groupwise landmark-based
metric](https://github.com/m-pilia/CorrespondingPointsMeanDistanceMetric) for
the Elastix image registration toolkit, together with an [accompanying blog
post](/posts/2018/09/23/goupwise-landmark-registration.html).
{% endevent %}

{% event project, July 2018 %}
Published [volume-raycasting](https://github.com/m-pilia/volume-raycasting), a
minimal GPU-accelerated raycaster with an [accompanying blog post
tutorial](https://martinopilia.com/posts/2018/09/17/volume-raycasting.html).

Initially developed as a research tool, it has later been used and cited by
unrelated researchers [[1]](https://doi.org/10.21105/joss.02580) and part of
the code has been incorporated in the official Qt6 SDK examples
[[2]](https://web.archive.org/web/20240721210046/https://doc.qt.io/qt-6/qtquick3d-attribution-alpha-blending-frag.html).
{% endevent %}

{% event academia, April 2018 %}
Published the [Disptools](https://github.com/m-pilia/disptools) project, a
medical imaging research toolkit implemented in C and CUDA with Python
bindings, instrumental to my work on medical imaging.

The project has been later used and cited by other unrelated researchers
[[1]](https://www.biorxiv.org/content/10.1101/2024.08.12.607581v1.full.pdf).
{% endevent %}

{% event academia, March 2018 %}
At the [Swedish Symposium on Image
Analysis](https://ssba.org.se/ssba18-symposium/) (SSBA) in Stockholm I
presented the research work performed as part of my then ongoing master thesis
project.
{% endevent %}

{% event project, June 2017 %}
Initial release of
[plasma-applet-ambientnoise](https://github.com/m-pilia/plasma-applet-ambientnoise),
a KDE plasmoid inspired by Ubuntu's Anoise, providing a native solution on KDE
with more flexible mixer controls.
{% endevent %}

{% event life, August 2016 %}
I moved to Uppsala, Sweden.
{% endevent %}

{% endtimeline  %}
