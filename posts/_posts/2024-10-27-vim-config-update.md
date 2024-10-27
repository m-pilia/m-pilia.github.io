---
layout: post
title: Vim and Neovim configuration overhaul
subtitle: A major rework after several years
image: /posts/img/nvim_config_update/cogs_grey.svg
image-license:
  url: "https://commons.wikimedia.org/wiki/File:Cog-icon-grey.svg"
  text: "Image: Wikimedia Commons (public domain)"
show-avatar: false
mathjax: false
tags: [vim, neovim]
---

I spent several hours over the past week testing Neovim features and plugins to
update my [vim and Neovim configuration](https://github.com/m-pilia/.vim), in
what became a major overhaul. This post is a concise summary of changes with
their rationale and directions.

I wanted to start this write-up with a background on the history of my (Neo)vim
setup and how it reached the point where it now stands. This however developed
into a lengthy text that I decided to publish as a [standalone
post](/posts/2024/10/27/vim-background.html).

The change is a fairly large[^8]
[commit](https://github.com/m-pilia/.vim/commit/a90c3ecc5c) to the
[m-pilia/.vim](https://github.com/m-pilia/.vim) GitHub repository, publicly
hosting my vim and Neovim configuration under version control.

# Background

As mentioned in the [other post](/posts/2024/10/27/vim-background.html), I have
been using Neovim for a few years, after many years as a vim user, but so far I
have not been fully committed to it, keeping my configuration
backward-compatible with vim and avoiding reliance on some of the
Neovim-specific built-in features in favour of more portable alternatives (a
chief example being [coc.nvim](https://github.com/neoclide/coc.nvim)).

I have now however reached a point where I no longer see the need for
backward-compatibility, and at the same time I see the Neovim ecosystem as
mature enough for a full migration.

Removing coc.nvim from my setup required to select and configure a set of
plugins to replace its numerous features. For some features I went back to the
plugins I used before adopting coc.nvim, for others I decided to experiment
with newer plugins that did not exist at the time.

# Language choice

Being compatible with vim,[^9] my configuration was entirely implemented in Vim
script.[^10] I will add some Lua alongside to it, but I do not see the need to
rewrite my entire configuration in Lua, for several reasons.

Lua is more performant than legacy Vim script, but when it comes to my own
configuration the difference is negligible.

Lua is also a generally cleaner and less error-prone language than Vim script,
which makes it a better choice to implement plugins. If I had to implement a
new Neovim plugin, Lua would be an unchallenged go-to choice.  However, when it
comes to simple configuration (especially when there is no need to implement
functions), this difference does not seriously come into play.

On the other hand, I find that Vim script can generally express the same
settings in a more terse and concise manner. This might be biased by the fact
that I have a long experience with Vim script, having implemented myself
several complex vim plugins. So it is definitely one of those situations where
your mileage may vary.

On the other hand, newer Neovim-specific settings come through the Neovim Lua
API and can be awkward to use in Vim script.

Last but not least, my personal configuration is not exactly small, and
rewriting perfectly functional, clean, and well-maintainable Vim script code
into Lua (just for the sake of it) would require a non-negligible amount of
time and effort that I would rather dedicate to more productive activities.

Based on these reasons, for now I see my configuration as being a mix of Vim
script and Lua, writing different parts with the language that I find most
suitable for the task.

# Plugin management

I never used a true plugin manager before, as I simply never saw the concrete
need for it. I used to keep my plugins as git submodules and add them to the
`runtimepath`. Since version 8, vim has a built-in [package
system](https://web.archive.org/web/20241008151151/https://vimhelp.org/repeat.txt.html#packages),
however I never fully migrated to it and sticked to
[pathogen](https://github.com/tpope/vim-pathogen) to manage the `runtimepath`
(because it is an extremely simple plugin, and it would avoid me the need to
reimplement a mechanism analogous to `g:pathogen_disabled`).

When migrating my configuration, however, I decided to give a chance to
[lazy.nvim](https://github.com/folke/lazy.nvim). I wanted to switch out from
using git submodules, with all their quirks, and I also liked the idea of being
able to easily break down the plugin configuration in smaller and
self-contained files for each plugin.[^2] As a side effect of the configuration
overhaul, my `vimrc`/`init.vim` halved in size, and there is likely margin
for further modularization in the future.

# Language servers

While coc.nvim makes it very simple to work with language servers by hiding all
the details and making everything work out-of-the-box (to the point of even
downloading and installing the servers for you in its own user data), going
back to manually managed language servers (with just the help of
[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)) felt like a breath
of fresh air.

On one hand, I like being in more direct control of installation and settings.
On the other hand, when something goes wrong, troubleshooting is a lot easier
with a more explicit configuration: I already know where to look, while on the
other hand, when something goes wrong in the guts of coc.nvim, troubleshooting
tends to be more involved, as it might boil down to dealing with quirks or
internal implementation details of coc.nvim itself.

# Autocompletion and snippets

Autocompletion is one of the most important IDE features to me, therefore one
of my first questions was related to which solution to adopt in my migration.

Dozens of completion plugins exist for vim and Neovim, but what first attracted
my attention was [built-in
autocompletion](https://github.com/neovim/neovim/pull/27339), currently
available in Neovim nightly and to be part of Neovim 0.11 in the future. This
work, driven by [Maria José Solano](https://github.com/MariaSolOs) (also author
of Neovim's built-in snippet implementation), makes it very easy to get
LSP-based autocompletion to work with only a handful lines of configuration,
potentially obsoleting the need for an autocompletion plugin.[^1]

With just [a few
lines](https://gist.github.com/m-pilia/2273f1c53bea11f201985e835706d810) of
configuration I got a nicely working pop-up-menu fed by the language server:

```lua
local lsp_au_group = vim.api.nvim_create_augroup('lsp_au_group',
                                                 {clear = true})

vim.api.nvim_create_autocmd({'LspAttach'}, {
    callback = function()
        local clients = vim.lsp.get_clients()
        for _, client in ipairs(clients) do
            local id = client.id
            vim.lsp.completion.enable(true, id, 0, {autotrigger = true})
        end
    end,
    group = lsp_au_group,
})
```

A few mappings allow me to reproduce the same setup I used with coc.nvim:

```vim
inoremap <silent> <expr> <tab> pumvisible() ? "\<C-n>" : "\<tab>"
inoremap <silent> <expr> <S-tab> pumvisible() ? "\<C-p>" : "\<S-tab>"
inoremap <silent> <C-space> <C-x><C-o>
inoremap <silent> <expr> <C-j> pumvisible() ? "\<C-y>" : "\<C-j>"
inoremap <silent> <expr> <bs> pumvisible() ? "\<bs>\<c-x>\<c-o>"
\                                          : v:lua.require('nvim-autopairs').autopairs_bs()
```

This looked very nice and promising, and I was almost tempted to adopt it as my
solution. However, while these days I rely mostly on just language servers, I
also wanted to be able to easily integrate snippets and other sources of
completion. I could have pieced together a custom solution, leveraging the
built-in [Neovim snippet
API](https://neovim.io/doc/user/lua.html#_lua-module:-vim.snippet) and creating
a custom
[completefunc](https://web.archive.org/web/20241002031717/https://vimdoc.sourceforge.net/htmldoc/options.html#'completefunc').

However this would have been akin to creating my own custom autocompletion
plug-in, for no particularly good reason. Therefore I opted for stock
solutions, namely [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) for
autocompletion and [LuaSnip](https://github.com/L3MON4D3/LuaSnip) for snippets.
In this process, I switched out of
[UltiSnips](https://github.com/SirVer/ultisnips) and ported my own custom
snippets from the UltiSnips format to the [JSON format used by
VSCode](https://web.archive.org/web/20240906214319/https://code.visualstudio.com/docs/editor/userdefinedsnippets#_create-your-own-snippets).[^3]

As a corollary, I promptly [added a nvim-cmp completion
source](https://github.com/m-pilia/vim-mediawiki/commit/7539fbbd63) to my own
[vim-mediawiki](https://github.com/m-pilia/vim-mediawiki) plugin. The task
itself was simple, as I could easily implement it as a Lua wrapper around the
existing coc.nvim source, converting inputs and outputs between the formats
used by the two plugins. Nevertheless, it was a useful way to have a peek under
the hood and work with the  nvim-cmp API from a plugin developer's
perspective.[^6]

# Auto-pairs

Many plugins offering automatic parentheses/delimiter closure ("auto-pairs")
have come and gone. I was generally unhappy with coc.nvim's auto-pairs
solution, which I had disabled in favour of
[auto-pairs](https://github.com/jiangmiao/auto-pairs). This plugin worked
sufficiently well for the use cases I wanted, however it had some quirks and
limitations and it has been unmaintained for a while.

For this reason, I decided to try a newer Neovim alternative, opting for
[nvim-autopairs](https://github.com/windwp/nvim-autopairs). While it seems to
have less rules defined out-of-the-box, its rule system seems to be strong and
versatile, and it should allow me to cover what I need. The configuration I
came up with during the migration will probably need some more refinement
iterations, but it should be good enough as a starting point.

# Gutter signs

I primarily need two features to work in the gutter:[^4] signs for diagnostics,
and signs for git diffs. For the former, Neovim now offers built-in gutter
signs for diagnostic, so that already works out of the box and I only needed a
few lines of Lua settings to get the desired appearance. For the latter, I went
back to [vim-gitgutter](https://github.com/airblade/vim-gitgutter), that I used
before coc.nvim and still seems to be a reasonable go-to solution for me.[^5]

# Status line

The status line looks unchanged, and remains based on
[lightline.vim](https://github.com/itchyny/lightline.vim). I only needed to
adjust the implementation of some of my custom sources, due to changes in
plugin backends.

<img src="/posts/img/nvim_config_update/lightline.png"
     class="center-block content-image-padded"
     style="width:100%;"
     markdown="1"/>

I have a compact representation of the git diff stats that relies on colour,
requiring different syntax highlight regions, and the definitions of these
regions might need to dynamically change upon changing vim mode, e.g. if the
status line theme uses different background colours for different modes.
Moreover, each of the three fields (added/changed/deleted) is visible only when
its value is nonzero, it is hidden otherwise. This dynamic behaviour makes it
slightly tedious to implement and requires [some custom
logic](https://github.com/m-pilia/.vim/blob/b000b7e7d3/autoload/aux/lightline.vim)
that I implemented in Vim script a few years ago, and I see no reason to port
to Lua at the moment, besides some changes needed to switch from the coc.nvim
API (used to get the git status data) to the vim-gitgutter API.

I also have a couple fields to the right to report the number of warning and
error diagnostics in the current buffer, and they also appear dynamically, only
when they have a nonzero value. These sources were however simple to port from
the coc.nvim API to vim-gitgutter's one.

# Misc cleanup

The migration has also been an occasion to remove plugins that are now
obsolete or that I realised I have no longer been using in a while. It also
allowed me to remove a significant amount of custom `autoload` code for
features that are now built-in in Neovim, or have been added to plugins that I
already use, or exist as standalone plugins that are sufficiently clean and
self-contained to be worth adding to my configuration.

# Future direction

I see this configuration refresh not as an arrival but rather as a starting
point. In late times my vim/Neovim configuration had been fairly stable and
almost stationary, likely due to the fact of being already fairly advanced,
paired with the fact that I am generally not motivated to make changes just for
the sake of it.[^7]

But I see some margin to further refine and improve my setup, so I will
evaluate improvements and possibly new plugins to try (or to develop myself) in
the future to cover more advanced use cases that I have been developing.

# Footnotes
{:footnotes}

[^1]: Technically, autocompletion plugins have never been strictly
      necessary, as it has always possible to get a working autocompletion by
      providing a user-made
      [omnifunc](https://web.archive.org/web/20241002031717/https://vimdoc.sourceforge.net/htmldoc/options.html#'omnifunc')
      or
      [completefunc](https://web.archive.org/web/20241002031717/https://vimdoc.sourceforge.net/htmldoc/options.html#'completefunc').
      Doing this robustly, however, boils down to implementing your own
      autocompletion plugin. Which, unless there is any particular reason to do
      it (such as doing things better or differently than existing plugins),
      ends up in reinventing the wheel.

[^2]: That would have always been possible to do by using smaller vim scripts
      and a mechanism to source them. But Lazy offers such mechanism basically
      out of the box and so, once more, no need to reinvent the wheel.

[^3]: LuaSnip supports different formats and has loaders for them. While Lua
      snippets are potentially more versatile, JSON ones are more portable and
      support all features I need at the moment. And of course nothing prevents
      me to also add custom Lua snippets to the side if more advanced features
      are needed.

[^4]: The "gutter" is the sign column to the left of the window.

[^5]: Once again, I am not obsessed with finding Lua solutions just for the
      sake of it.

[^6]: The only limitation I found was that
      [Vader](https://github.com/junegunn/vader.vim) tests did not seem to play
      well with Lua, and I would get an error due to the fact that apparently,
      when calling the `complete()` function from a Vader test, `table` arguments
      would end up having `userdata` type instead. Juggling with `:lua`,
      `luaeval()`, and even hiding the calls inside Lua wrapper scripts did not
      help. I will need to look into this, and probably consider a different
      unit test frameworks for Lua plugins.

[^7]: I often see and hear the word "modern" being used in this context. I
      think that word is not rarely misused.

[^8]: While I greatly prefer small and self-contained changes, and I vehemently
      advocate for them at work, in this case I think an atomic update is the
      most reasonable solution, while small incremental configuration changes
      would be harder to follow and would almost unavoidably leave parts of the
      configuration broken in the intermediate steps.

[^9]: I am capitalizing "vim" (as in the text editor) as lowercase, and "Vim
      script" (as in the programming language, also known as "VimL") as
      uppercase, following the capitalization used in the official
      documentation for the latter.

[^10]: What is now known as "Vim script version 1", i.e. legacy Vim script
       without any of the new language features introduced since Vim 9.
