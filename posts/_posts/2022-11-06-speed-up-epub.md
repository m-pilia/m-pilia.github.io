---
layout: post
title: How I sped up an e-book
subtitle: Making an unreasonably slow EPUB usable
image: /posts/img/epub_speed/digitalbook.jpg
image-license:
  url: https://commons.wikimedia.org/wiki/File:Digitalbook.jpg
  text: "Image: EFF (CC-BY 3.0 US)"
show-avatar: false
mathjax: false
tags: [epub, random, reading]
---

This post is a short recap of a funny situation where I had to deal with a
seemingly innocent-looking e-book that ended up being unreadable on my
e-reader. The solution turned out to be relatively simple, but I have not found
references to any similar problem on the web, therefore I decided to share my
tale with the hope that it can be of help.


# The issue

Seeking for a deep dive into the new C++20 features, deeper than what I have
explored so far, I recently bought a copy of [_C++20 &ndash; The Complete
Guide_](http://www.cppstd20.com) by Nicolai M. Josuttis. Besides the popularity
of the author and the depth of the coverage (even too deep for a general
overview), one of the reasons I opted for this book is that it comes in EPUB
format, unlike other competitors that are only available in PDF. Since I want
to read it on my e-reader, EPUB is the most convenient format.

After pushing the book and trying to open it on my e-reader, the device hung
and after a minute or so it performed a soft reset. That was new and
unexpected. After a few attempts the reader finally managed to load the book.
However, a page turn would take 5-10 seconds, making the reading experience
miserable (and battery life even more miserable). And what if I want to switch
to another book and then re-load this one later? Perish the thought, I guess.

# Blame game

The good news is that the website of Leanpub, publisher of the book, contains
some information regarding device compatibility issues. The bad news is that
such information is not particularly encouraging. With an FAQ titled _"I bought
a book and it doesn't open in my Kobo reader. What can I do?"_, the answer
apparently is [_"[...] if you are not able to see the book on your Kobo device,
the issue may be with your Kobo device
itself"_](https://web.archive.org/web/20221106190133/http://help.leanpub.com/en/articles/3882373-a-bought-a-book-and-it-doesn-t-open-in-my-kobo-reader-what-can-i-do).
Followed by a suggestion to report the issue to Kobo. Surely not the most
helpful help page ever.

While my Kobo is a few years old, I felt pretty confident that the device was
fine, given the amount of e-books of all sorts that I regularly read, including
many programming books from well established publishers, with no issues
whatsoever.

I must admit, the soft resets were suspicious: assuming that no particular
software bug was involved (e.g. invalid access, unhandled exception, or other
sort of logic error or undefined behaviour in whatever language the reading
application is implemented), they might have possibly been due to running
out-of-memory while loading the file, or maybe to a task unexpectedly taking so
long to the point of triggering a watchdog bite. Regardless, I leaned to think
that the unreasonable slowness of this book was not (entirely) the e-reader's
fault, but rather due to some issue with the EPUB file itself.

# EPUB unpacked

I am familiar to some degree with the EPUB format, having myself written a
handful EPUB files from scratch many years ago. For this reason, I decided to
open the hood and try to figure out if I could troubleshoot this on my own. A
nice aspect of Leanpub is that their e-books are DRM-free, and this allowed me
to investigate the problem without complications.

An EPUB file is nothing more than a zip archive in disguise, and unpacking it
reveals the content, typically being composed of a bunch of (X)HTML files
containing the actual text of the book, accompanied by CSS files, images, and a
few metadata files. In essence, an EPUB file does not look too much different
from an old-school static website.

E-readers are fairly constrained devices, with small memory and a CPU with
limited computing power that spends most of its time sleeping. Given that the
e-ink display is passive, the moments the e-reader is actually drawing power
are mostly during page turns, when a new page is rendered and printed to
screen, where it stays without consuming further power.[^1] This is key to
attain the months-long battery life that today's e-readers are able to provide.

Given the limited hardware resources, there are a few key optimisation aspects
to keep in mind when creating an EPUB, in order to make page rendering as
efficient as possible. Besides limiting usage of images and their resolution,
making the text source leaner has also an important impact. Since sections are
loaded individually, keeping the size of each HTML file small allows for faster
load (Calibre recommends no larger than 250&nbsp;kB). For this reason, it is
better to split chapters in separate files rather than clumping them together,
and to avoid in-line CSS in favour of separate style files. And last but not
least, keeping the HTML as simple as possible will impact the rendering speed,
since the more tags need to be parsed, the more work will be required to render
each page.

# The colour out of space

First thing I did was to open the book with Calibre's EPUB viewer on my laptop,
to check whether it was completely broken or if it would work on a different
reading application. The book opened and seemed to work just fine, which is
good.

However, something unusual caught my eye: the code snippets were very
colourful, being rendered with syntax highlighting. While I must admit the code
examples look pretty on my laptop monitor in their highlighted format, this is
something unusual in printed books and e-books targeted for e-ink readers, and
therefore it rang an ominous alarm bell in my head.

To verify my suspicion, I opened the book with Calibre's EPUB editor to take a
look at the source code, and that only made the alarm bell ring louder. A
simple snippet like the following

```c++
std::vector<Value> coll;
...;
std::sort(coll.begin(), coll.end());  // uses operator < to sort
```

looks like this in the source

```html
<figure class="code" dir="ltr">
<div class="highlight"><pre><code></code><code class="n">std</code><code class="o">::</code><code class="n">vector</code><code class="o">&lt;</code><code class="n">Value</code><code class="o">&gt;</code> <code class="n">coll</code><code class="p">;</code>
<code class="p">...;</code>
<code class="n">std</code><code class="o">::</code><code class="n">sort</code><code class="p">(</code><code class="n">coll</code><code class="p">.</code><code class="n">begin</code><code class="p">(),</code> <code class="n">coll</code><code class="p">.</code><code class="n">end</code><code class="p">());</code>  <code class="c1">// uses operator &lt; to sort</code>
</pre></div>
</figure>
```

Ouch. That is a lot of HTML tags to parse and styles to apply for just a couple lines
of code. And considering that code examples represent a large fraction if not
the majority of this book's content...

# The solution

While syntax highlighting is indeed nice, the e-ink screen of most e-readers
(including mine) is gray-scale, and for this reason applying colour to text is
pointless for a file optimised for e-readers. To test my theory, I removed all
of the <code>&lt;code&gt;</code> tags from the HTML, leaving the format of the
source snippets untouched except for the colour.

Easy to imagine, the book contained lots and lots of source samples, and
therefore thousands of <code>&lt;code&gt;</code> tags, so the removal task
required some automation. As usual, a regular expression [saves the
day](https://xkcd.com/208/) and allows to fix this with a one-liner. The regex
is actually very easy to write when using the lazy version of the Kleene star.
This rules out tools like <code>sed</code> or <code>grep</code>, given that
most of their implementations do not include lazy matching. Thankfully,
<code>perl</code> is up to the task:

```sh
perl -pi -e 's|<code *(class="[^"]*")?>(.*?)</code>|\2|g' *.xhtml
```

Generally speaking, I would not recommend parsing HTML with regular
expressions, given its potential to awaken the Great Old Ones and make Stack
Overflow users' minds [descend into
madness](https://stackoverflow.com/a/1732454). But this is a one-time, very
specific job, so hopefully no Eldritch horror was awakened in the process. Here
we trust that the HTML format is consistent, without out-of-place whitespace or
other unexpected characters, and that the element does not contain unexpected
attributes. Also, we know that the snippets in the book are C++ code, so we are
fairly confident that they will not contain a closing
<code>&lt;/code&gt;</code> tag.[^2]

Even without resorting to regular expressions, it is still possible to
accomplish this task in a relatively simple manner by using an XML parser (e.g.
with a small Python script using the
[html.parser](https://docs.python.org/3/library/html.parser.html) module). And
even a GUI option is available: Calibre includes a feature-rich EPUB editor
that allows to edit the source, and provides a specific filter to remove HTML
tags while keeping their content (Tools &rarr; Transform HTML &rarr; Add rule
&rarr; Remove tag only).

# Conclusion

After packing and pushing the modified file to the e-reader, it was time for
testing the solution. Removing all those tags did the trick, and brought the
page turning time down to a reasonable duration, that feels consistent with
other e-books. Opening the book from the library is still very slow, so there
is definitely room for more optimisation, but at least it no longer seems to
crash the device.

The conclusion of this little story is that syntax highlighting is best kept
off from an e-book targeting e-readers. After all, if a book is distributed
both in PDF and EPUB formats, it would probably make sense to optimise the
former for larger displays (PC, laptops, tablets, etc.) and the latter for
e-readers.

# Footnotes
{:footnotes}

[^1]:
    Another continuous power sink is screen illumination, if used. However, I
    personally avoid it, since one of the main reasons for using an e-reader is
    the screen's passive nature, and I prefer to use a traditional reading
    light. On top of that, avoiding built-in screen illumination grants a huge
    boost to battery life.

[^2]:
    To be fair, a C++ snippet could contain a comment or a string literal, in
    turn containing a snippet of HTML featuring the <code>&lt;/code&gt;</code>
    tag. Even in this remote possibility, the C++ snipped would still be
    embedded inside an HTML element, where <code>&lt;</code> and
    <code>&gt;</code> need to be escaped and therefore would not match the
    regular expression.
