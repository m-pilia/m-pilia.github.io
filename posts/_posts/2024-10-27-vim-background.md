---
layout: post
title: Short recap of my history as a vim and Neovim user
subtitle: My (Neo)vim journey so far
image: /posts/img/nvim_config_update/nvim_vim.svg
image-license:
  text: "Image: Jason Long (CC-BY 3.0) and vim.org (Vim license)"
show-avatar: false
mathjax: false
tags: [vim, neovim]
---

When writing [a post](/posts/2024/10/27/vim-config-update.html) about my recent
(Neo)vim configuration overhaul, I wanted to start with an overview of how my
(Neo)vim usage evolved in time and how it reached the point it stands at now.
This overview ended up being a fairly lengthy write-up, which I therefore
decided to publish as a standalone post.

# Background

My (Neo)vim configuration always keeps up with the times, but it usually moves
cautiously. While in general I value cutting-edge features and keeping up with
latest trends and developments, vim is probably the single most important tool
in my box and it is heavily ingrained in both my work and personal life. For
that reason, when it comes to my vim setup, I highly value stability and
consistency. I sometimes wait before jumping on board of the latest vim or
Neovim trends, and I often give time for features to mature first (while
carefully keeping watch on how they develop).

I am a long-standing vim user, and (Neo)vim has been my text editor and
development environment for a variety of programming languages and text
document types in school, work, and personal life. For that reason, my vim
setup and configuration has evolved through time to support this, encompassing
the choice and setup of a variety of plugins.

# Key features

When it comes to programming, the two most important IDE features to me are
inline diagnostics and semantic autocompletion.

Shortening the feedback loop is one of the most important aspects of optimising
a developer's way of working, and being able to see diagnostics as I type is
one of the most extreme forms of
[shift-left](https://en.wikipedia.org/wiki/Shift-left_testing).[^5] For the
same reason, I value using as many linters and static analysers as possible,
not just to improve quality of my work but also to learn more and more about
code quality and best practices through them.

Additionally, I primarily work with large and complex codebases, and I often
have to quickly insert myself into projects and codebases I am unfamiliar with.
Being able to quickly see APIs as I type through semantic autocompletion is a
major time-saver and very helpful in reducing cognitive burden.

# The YouCompleteMe era

My first main setup for inline diagnostics and semantic autocompletion was
based on [YouCompleteMe](https://github.com/ycm-core/YouCompleteMe) (YCM),
originally developed by [Val Markovic](https://github.com/Valloric). With its
support for C, C++, and Python, it was a major pillar in my daily work. That
setup carried me through school, research work, and my first industrial job.

# Advent of the Language Server Protocol

Microsoft introduced the [Language Server
Protocol](https://microsoft.github.io/language-server-protocol/) (LSP) as a
building block for their well-known next-generation editor, Visual Studio Code
(VSCode). For me the LSP was love at first sight, as it allowed decoupling IDE
front-ends and back-ends in a standardised and interoperable fashion. Flocks of
language servers were developed for all sorts of languages, and my dream of
having inline diagnostics and semantic autocompletion for all the languages I
wanted was becoming true.

While YCM had already pioneered the idea of decoupling the semantic back-end
from the text editor[^1] before LSP itself, the LSP had a much broader span and
unfortunately the YCM project was a bit slow to switch to the new protocol.
That pushed me to abandon YCM in favour of an LSP client.

There were several options for vim clients since early times, and after testing
a few alternatives I decided to go with
[vim-lsp](https://github.com/prabirshrestha/vim-lsp), which seemed the
leanest[^2] to me while at the same time having all the features I wanted (I
contributed a few features to the project myself).

# coc.nvim

I sticked to vim-lsp only for a relatively short period, as soon after I
decided to try a more ambitious plugin developed by a subset of the Chinese
(Neo)vim community, [coc.nvim](https://github.com/neoclide/coc.nvim), whose
aspiration was to port the VSCode ecosystem to (Neo)vim. Given the big feature
scope of coc.nvim, this was a major overhaul of my vim setup.[^7]

While coc.nvim served me well for a long time, I have always been torn over it
since the very beginning, and even before switching to it I was already
hesitant. coc.nvim is a big and complex plugin that relies on its own node.js
daemon, and with its own plugin management (plugin-for-the-plugin) and an
ecosystem of TypeScript plugins. This has its pros and cons.

On the good side, it provides a feature-rich and consistent experience, with
lots of complex features working out-of-the-box and integrating consistently
with each other. As a consequence, it allows to replace many vim plugins with a
single plugin, significantly simplifying the vim setup. It also works
consistently with both vim and Neovim, and it therefore easily lends itself to
act as a compatibility layer for many advanced features.

On the flip side, it is a big and complex plugin that interferes with lots of
other plugins, acting a bit as a monolith at the expense of modularity. Many
features mimic the VSCode behaviour, which is a boon for some and a curse for
others. Also, it depends on node.js, which is often an annoyance, especially at
work where I hardly ever have node.js as part of my development environment.

# Tentative Neovim approach

When the Neovim project started in 2015 I really liked the idea behind it, as I
saw the need for a more modern development approach in the vim project.
However, I did not jump ship immediately. In its early days Neovim suffered of
stability and platform portability issues. It was also not obvious whether the
project would take off or if it would end up as a dead end.[^3] I therefore
preferred to wait and see whether the project would stabilize.

Neovim turned out to be a solid project that started to offer not just a better
community-driven (and test-driven) development of the editor itself, but also
many high-quality features that vim lacked or was behind in terms of
development. For that reason, I later switched to Neovim as my daily editor,
but I decided to keep all my configuration backward-compatible with vim. In
this sense, coc.nvim also helped by acting as a compatibility layer between the
two editors.

# Shifting to Neovim

As time passed, it became clear that I was not going to switch back to vim. I
regardless kept my configuration backward compatible for a prolonged period.
I also kept using coc.nvim, despite of more and more features becoming Neovim
built-ins through time, such as the native LSP client in 0.5, native snippet
expansion support in 0.10, and the incoming native autocompletion support in
0.11.

There were different reasons for this. Besides the aforementioned backward
compatibility with vim, and waiting for built-in features (and the plugin
ecosystem built around them) to mature, coc.nvim still worked very well for me
and provided all the features I wanted in the way I wanted them. Conversely, at
the time experimenting with newest Neovim's built-in features and related
plugins required a more complex configuration with more plugins, more glue
code, and the result was still not as satisfactory as coc.nvim.

Last but not least, I did not see the need to change just for the sake of
change. While I prefer the idea of using built-in features where possible, that
by itself did not justify a change, for the reasons mentioned above.

Similarly, while many Neovim users have their entire configuration in Lua, I
did not see a reason to port my entire configuration to Lua. While I see Lua as
a much "better"[^8] scripting language than Vim script,[^6] I have an advanced
knowledge of Vim script myself, having implemented and published several
complex plugins, which differentiates me from newcoming Neovim users. And for
simpler things I find a Vim script configuration cleaner and more concise than
a Lua counterpart.[^4]

# Embracing Neovim

However, Neovim features and plugins steadily matured, and I eventually reached
the point where a full switch to Neovim was meaningful, and abandoning coc.nvim
was a worthwhile improvement.

Neovim built-ins and plugins could now provide the features I wanted in the way
I wanted them, with also better performance than coc.nvim and removing the need
for a cumbersome node.js dependency. I also liked the possibility of a more
modular configuration, with a mix-and-match of plugins that is not possible
with coc.nvim, and a natural way to break down my configuration into many
smaller and more self-contained Lua files.

Another aspect is that vim itself is also taking new and incompatible
directions. [Vim9
script](https://web.archive.org/web/20241004195536/https://vim-jp.org/vimdoc-en/vim9.html)
is the future of vim scripting and plugin development, however it is
incompatible with Neovim and, understandably, Neovim only guarantees
compatibility with legacy Vim scrip (which is now known as [Vim script version
1](https://web.archive.org/web/20240325015229/https://vim-jp.org/vimdoc-en/eval.html#scriptversion)).
For this reason, while I think Vim9 script is a great improvement over legacy
Vim script, I am not invested into it. I see Neovim as my main driver now,
and I have a hard time justifying an investment of my time and effort into
incompatible solutions.

This decision led me to what became a major overhaul of my (Neo)vim setup and
configuration. I will however not get into details here, as this configuration
switch is the subject of a [dedicated
post](/posts/2024/10/27/vim-config-update.html).

# Footnotes

{:footnotes}

[^1]: For instance, there was [an Emacs
      client](https://github.com/abingham/emacs-ycmd) that used the same YCM
      daemon.

[^2]: I highly value cleanliness and simplicity.

[^3]: The Neovim schism injected some renewed energy in the roadmap of vim
      itself, for instance pushing towards the implementation of long-requested
      features such as terminal embedding, asynchronous execution, etc.

[^4]: Admittedly, this might also be influenced by my long experience with
      Vim script.

[^5]: To give a practical example, in one of my previous jobs we used to have
      our in-house C coding guidelines, and an in-house tool developed to check
      compliance and enforce them (back then `clang-tidy` was not as viable as
      it is today). I implemented a vim plugin to integrate our in-house coding
      guidelines linter in vim and Neovim, which became a user-driven company
      tool, and I shortly followed it up with implementing an analogous plugin
      for VSCode to offer the same experience to other coworkers (even though I
      did not use VSCode myself, it was the most popular IDE at work there).

[^6]: I am capitalizing "vim" (as in the text editor) as lowercase, and "Vim
      script" (as in the programming language, also known as "VimL"") as
      uppercase, following the capitalization used in the official
      documentation for the latter.

[^7]:  I still remember spending several hours during a long layover at
       Amsterdam Schiphol porting my configuration to coc.nvim.

[^8]: "Better" in the sense of cleaner, less error-prone, and with less obscure
      idiosyncrasies.
