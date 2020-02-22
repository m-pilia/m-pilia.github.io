---
layout: post
title: Migration to Jekyll Scholar and GitHub Actions
subtitle: New bibliography management and build system for the website
image: /posts/img/migration/actions.png
show-avatar: false
mathjax: false
tags: [jekyll scholar, github actions]
---

This is a meta post that describes the technical updates I recently performed
to this very website. Since length and complexity of the articles were growing,
I decided it was time to switch to Jekyll Scholar as the bibliography
management tool. This required a little refactoring and a change to the build
system used to generate the website. Together with the update, I did some
cleanup of the code for the site, that I am now open-sourcing.

# GitHub Pages

As it is easy to guess, this website is hosted on GitHub Pages. [GitHub
Pages](https://pages.github.com/) is a free solution offered by GitHub to host
static websites, allowing to either write HTML, CSS, and JS code by hand, or to
use the [Jekyll](https://jekyllrb.com/) framework to automatically generate the
site from Markdown and Liquid sources. While I personally find Markdown a
little simplistic and I would prefer to use a more versatile and structured
language for technical writing on the web, such as
[reStructuredText](https://en.wikipedia.org/wiki/ReStructuredText), the
combination with Liquid and other Jekyll features somehow compensates for its
weaknesses and makes it a sufficiently expressive tool.

By default, any GitHub repository can automatically generate a website, with
the purpose of hosting documentation for the corresponding project. The code
for the website is stored in a branch named <tt>gh-pages</tt>, and the
corresponding site is published at <tt>&lt;repository-name&gt;.github.io</tt>.
Moreover, each user or organisation can host a personal site by creating a
repository named <tt>&lt;username&gt;.github.io</tt>, where
<tt>&lt;username&gt;</tt> is the name of the user or organisation on GitHub. In
this case, the sources of the site can be stored in the <tt>master</tt> branch.

# Bibliography management and Jekyll Scholar

When I first put together my website, I decided to start simple and rely on a
minimal GitHub Pages setup, so in the early posts I just wrote the
bibliographical entries as plain text, using HTML anchors to jump to citations
in the bibliography section. Since the posts grew bigger and with a longer
reference list, it quickly became clear that such way of working was not going
to scale up well.

The subsequent decision was to migrate to a bibliography management tool. Since
I habitually work with TeX and BibTeX, the obvious choice was to move to
[Jekyll Scholar](https://github.com/inukshuk/jekyll-scholar), a plugin that is
more or less the equivalent of <tt>biblatex</tt> or <tt>natbib</tt> for the
Jekyll world. It allows to store bibliographical entries in a standard BibTeX
file, and defines some commands to create in-line citations (similarly to the
<tt>\cite{}</tt> command in LaTeX). A rich and flexible set of [configuration
options](https://github.com/inukshuk/jekyll-scholar#configuration) can be
specified in the Jekyll <tt>_config.yml</tt>, and it is possible to fully
define the citation style using the [Citation Style
Language](https://citationstyles.org/) (CLS).

Adding Jekyll Scholar to the configuration is straightforward, and it only
requires to replace the <tt>github-pages</tt> gem with the <tt>jekyll</tt> and
<tt>jekyll-scholar</tt> in the
[Gemfile](https://github.com/m-pilia/m-pilia.github.io/commit/990e15e30da92afe81abf379f9dd5c6e3b6e3476#diff-8b7db4d5cc4b8f6dc8feb7030baa2478L3-R4)
and
[_config.yml](https://github.com/m-pilia/m-pilia.github.io/commit/990e15e30da92afe81abf379f9dd5c6e3b6e3476#diff-e79a60dc6b85309ae70a6ea8261eaf95R80-R83).

# A bit of customisations

While Jekyll Scholar works out-of-the-box for most use cases, I decided to
tweak a handful settings to better fit my needs. I opted for the IEEE style,
since it is the one I most often use in my work, and one change I made was to
allow inserting a hyperlink in the title of an entry in the bibliography, that
looks to me like the most natural way of formatting a citation on the web. To
do so, I created a [custom
version](https://github.com/m-pilia/m-pilia.github.io/blob/28336d253714/_bibliography/my-ieee.cls)
of the IEEE stylesheet from the [CLS
repository](https://github.com/citation-style-language/styles), simply [adding
an HTML &lt;a&gt;
tag](https://github.com/m-pilia/m-pilia.github.io/blob/28336d253714/_bibliography/my-ieee.cls#L132-L140)
to the title if the <tt>url</tt> field in the corresponding BibTeX entry is
filled.[^1]

```xml
<choose>
  <if variable="URL">
    <text variable="URL" prefix="&lt;a href=&quot;" suffix="&quot;&gt;"/>
    <text variable="title" quotes="true" suffix="&lt;/a&gt;"/>
  </if>
  <else>
    <text variable="title" quotes="true"/>
  </else>
</choose>
```

To fully reproduce the IEEE style, the numbers in each bibliographical entry
should be enclosed within square brackets, and it is possible to achieve this
with a few line of CSS, [altering the
style](https://github.com/m-pilia/m-pilia.github.io/blob/28336d253714cab8/css/main.css#L784-L800)
of the <tt>&lt;li&gt;</tt> items in the bibliography. The numbering is
contained in the <tt>:before</tt> pseudo-element of each list item, and the
<tt>content</tt> property allows to define a custom template for the ordinal.
Fixing the <tt>width</tt> and using a negative <tt>margin-left</tt> allows to
shift the numbering to the left, out of the text column, as it would appear in
a bibliography generated with LaTeX.

```css
ol.bibliography {
  counter-reset: item
}

ol.bibliography li {
  list-style-type: none;
  margin: 30px 0;
}

ol.bibliography li:before {
  content: "[" counter(item) "] ";
  counter-increment: item;
  position: absolute;
  text-align: right;
  width: 4em;
  margin-left: -4.4em;
}
```

Since my theme includes a fixed bar on the top, [adjusting the scroll
padding](https://github.com/m-pilia/m-pilia.github.io/commit/a3b7e1ac876eda04b5d073c6918eb521357181c9)
prevents it from covering the text when jumping to anchors such as citations or
footnotes.

```css
html {
  scroll-padding-top: 50px; /* compensate for the navigation bar height */
}
```

# Automated build

While Jekyll Scholar seems a perfect fit for the task, there is a small catch.
For obvious security reasons, GitHub Pages does not allow to run arbitrary Ruby
code in its build process, therefore it is not possible to use third-party
Jekyll modules at will, and only a restricted handful of selected Ruby gems can
be loaded. Unfortunately, Jekyll Scholar is not among those, so it is not
possible to use it and at the same time rely on the automated GitHub Pages
build system.

Since GitHub Pages allows to upload pre-built HTML and CSS for the site as an
alternative to the Jekyll sources, a solution is to set up a continuous
integration pipeline to build the site on each push and publish the build
output on the <tt>master</tt> branch. Several well known CI systems such as
[Travis](https://travis-ci.org/), [AppVeyor](https://www.appveyor.com/), and
[CicleCI](https://circleci.com/) offer good integration with GitHub and have
been around for years. However, GitHub recently launched its in-house
continuous integration system, [GitHub
Actions](https://github.com/features/actions), and I decided to use it for this
task.

# GitHub Actions to the rescue

GitHub Actions is conceptually similarly to its predecessors, and its
configuration consists of workflows composed of one or more jobs, where each
job is a sequence of build steps. Each step is described by a bash script, and
the whole configuration is defined in a YAML file stored within the repository,
in the <tt>.github/workflows</tt> folder.

So far, everything seems fairly consistent with other popular CI services.
However, one interesting feature of GitHub Actions is that it is possible to
define build steps (the so-called <i>actions</i>) as re-usable blocks, whose
code is stored within a GitHub repository and it is published on the [GitHub
Marketplace](https://github.com/marketplace?type=actions).

A simple workflow with one job looks similar to the following. The code is
mostly self-explanatory, and it is possible to observe how a common action such
as git checkout is not coded explicitly, but uses the <tt>actions/checkout</tt>
from the Marketplace. For stability and reproducibility, the action invoked in
the build is pinned to a specific version (<tt>v1</tt> in this example). It is
also worth noting how easily the workflow integrates with GitHub: a secret
token to perform restricted actions on the repository, such as a <tt>git
push</tt>, is automatically generated and exposed (as
<tt>{%raw%}${{secrets.GITHUB_TOKEN}}{%endraw%}</tt>) with no need to perform
any configuration steps at all on the repository side.

```yaml
name: My Workflow

on:
  push:
    branches:
    - source

jobs:
  MyJob:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v1
      with:
        ref: source
    - name: Build
      run: |
        make all
    - name: Deploy
      env:
        GITHUB_TOKEN: {%raw%}${{secrets.GITHUB_TOKEN}}{%endraw%}
      run: |
        ./deploy.sh "${GITHUB_TOKEN}"
```

Since most CI workflows involve a lot of common steps, being able to
redistribute canned actions as ready-to-use packages greatly helps code reuse
and simplifies the configuration of workflows. Obviously, relying on pre-packed
code introduces external dependencies in the build process but, as long as each
action is pinned to a known version, it is possible to find a good balance
between not re-inventing the wheel and not relying too much on external
resources.

# Coding the build and deployment

With these ingredients, it is possible to set up a fully automated [build and
deployment
pipeline](https://github.com/m-pilia/m-pilia.github.io/commit/4e18b41ae01591ce1f9f1e793c2c76cd7bf962b5)
for our website. In order to perform a Jekyll build, a Ruby environment is
required, and for this purpose it is possible to use the
<tt>actions/setup-ruby</tt> Action, that will perform the required set-up for
us.

```yaml
- name: Set up Ruby 2.6
  uses: actions/setup-ruby@v1
  with:
    ruby-version: 2.6.x
```

The actual build step is then straightforward:
```yaml
- name: Build Jekyll site
  run: |
    set -xo pipefail
    rm -rf _site/*
    gem install bundler
    bundle install
    bundle exec jekyll build
    cp CNAME _site/CNAME
```

Jekyll stores the build artifacts in the <tt>_site</tt> folder. The last line
of the script is just creating a copy of the <tt>CNAME</tt> file inside the
artifact folder, to have it in the final output.

The final step is the deployment of the website, that is performed by
committing and pushing the artifacts to the <tt>master</tt> branch of the
website. I moved the Jekyll sources to a branch named <tt>source</tt>, that I
also set as the default branch for the git repository.

Here I explicitly coded the deployment step. The first couple lines set up the
git environment. <tt>action@github.com</tt> is the e-mail address associated to
the GitHub Actions bot account, so the commits pushed by the workflow will be
clearly visible as such in the repository history. The <tt>master</tt> branch
is checked out, since the output will be committed there.

```bash
git config --local user.email "action@github.com"
git config --local user.name "GitHub Action"
git checkout master
```

The next move is to wipe everything except the build artifacts, stored within
the <tt>_site</tt> directory, and subsequently move the content of the
<tt>_site</tt> folder to the root of the repository.

```bash
ls -Q | grep -v _site | xargs rm -rf
mv _site/* .
rm -rf _site
rm -rf .jekyll-cache
```

Last but not least, the step checks if anything changed and, if so, it creates
a new commit and pushes it to the GitHub repository. To make it easier to
backtrack where the changes came from, the SHA of the commit in the
<tt>source</tt> branch used in the build is included in the commit message.

```bash
[[ -n "$(git status --porcelain)" ]] || exit 0
git add .
git commit -m "Build $(git rev-parse source | grep -o '^.\{10\}')"
git push "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" master
```

To sum up, the whole deployment step looks as follows:

```yaml
- name: Deploy
  env:
    GITHUB_TOKEN: {%raw%}${{secrets.GITHUB_TOKEN}}{%endraw%}
  run: |
    set -xo pipefail
    git config --local user.email "action@github.com"
    git config --local user.name "GitHub Action"
    git checkout master
    ls -Q | grep -v _site | xargs rm -rf
    mv _site/* .
    rm -rf _site
    rm -rf .jekyll-cache
    [[ -n "$(git status --porcelain)" ]] || exit 0
    git add .
    git commit -m "Build $(git rev-parse source | grep -o '^.\{10\}')"
    git push "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" master
```

Now, after any commit to the <tt>source</tt> branch, a corresponding commit
with the build output is automatically deployed to the <tt>master</tt> branch.

<img src="/posts/img/migration/actions_history.png"
     class="center-block"
     style="width:100%;"
     markdown="1"/>

The full source code for the website is [available on
GitHub](https://github.com/m-pilia/m-pilia.github.io). Enjoy!

# Footnotes
{:footnotes}

[^1]:
    On Jekyll 4 and Jekyll Scholar 6, the output from the processing of the CLS
    is not further parsed by Jekyll and it is treated as literal. In order to
    insert HTML code in the CLS parsing stage, it is necessary to [disable the
    escaping](https://github.com/m-pilia/m-pilia.github.io/commit/28336d253714ca#diff-37bc4d55969f1bbc3ad9a5ac561ffb04R1-R14)
    of HTML code. Kudos to Sylvester Keil for [the
    hint](https://github.com/inukshuk/jekyll-scholar/issues/30#issuecomment-558040712).
