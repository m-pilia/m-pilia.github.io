---
layout: post
title: One thing you must know before disassembling your G502 X
subtitle: Just to make sure you can put it back together
image: /posts/img/mouse_fixing/springs.jpg
image-license:
  url:
  text: "Image: Own work (CC-BY-SA 4.0)"
show-avatar: false
mathjax: false
tags: [mouse, repair]
---

There are two small springs under the scroll wheel assembly. Be careful to look
for them when you remove it and do not let them jump out, or you risk losing
them.

Now, with that off my chest, a bit of backtracking. The purpose of this post is
to share a small bit of useful information that can be helpful when
disassembling a G502 mouse, and doing that I take the occasion to share some
thoughts about the device.

I usually dislike talking about (or even making passing mentions of) my
hardware gear, which in my view boils down to free and uncalled-for
advertisement. In this circumstance however I got inspired by technical aspects
and I want to rather share a critical view of the device with the hope it can
be useful to others.

# Background

I have been using my G502 X Lightspeed for about two years and half, with
moderate satisfaction. At the time I bought it I was completely renewing my
home desk setup, and this model was the only mouse that, at the time, fulfilled
all the requirements I had defined:[^1]
* USB-C connector.
* Unlockable scroll wheel.
* Wireless, but with the option to work wired over USB cable.
* At least 7 buttons.
* Fully programmable with on-board memory.
* Bonus: No RGB.

Logitech using their own proprietary wireless charging protocol, as opposed to
the more ubiquitous Qi standard, was concerning, but at the time I had not made
my mind yet on the matter of wireless charging. On the other hand, I was
intrigued by Logitech's approach to wireless charging not requiring to park the
mouse on a dedicated charging spot and allowing to charge even while using
it,[^2] to the point that about one year later I decided to add a Powerplay mat
to my setup. I ended up liking the benefits of wireless charging without having
to even think about the battery at all.[^4]

# Two years and half later

I have been using the mouse for about two years and half, which I think makes
it a much better point in time to share a critical review, compared to most
"professional" reviews written after just a few days (if not hours) of usage.

I have mixed feelings about the device, but I think my view is more positive
than negative.

The G502 X is a very lightweight mouse, so not for everyone's taste. I am not a
hardcore gamer and I do not care about gaming "performance", which is one of
the loudest drums being beaten in the advertisement of high-end desktop
peripherals. However, using a lighter mouse is beneficial for ergonomic
reasons, which is an important aspect to keep in mind when your whole work time
(and a non-negligible amount of your off-work hours) revolve around your
desk.[^3]

When first trying the device, its lightness gave it almost a cheap feeling,
contrasting to the good-looking quality of the build, but that went away fast
as I got used to it.

The switches are also very light. I was worried about the bad reputation of
previous G502 models' switches, but apparently the G502 X uses different parts
and thankfully I have not had any issues with them so far.

The original scroll wheel felt lightweighted but with a firm brake (if you have
never used an unlockable scroll wheel I highly recommend giving it a try), but
its durability has obviously been disappointing, breaking after only two years
and half of usage.[^5] Even after taking it apart I am still not completely
sure what exactly broke, technically the wheel was still functional (including
the unlocking function) but it suddenly became very hard to turn, regardless of
whether it was locked or unlocked.[^6]

# What about left-handed users?

I use the mouse with both hands, but primarily with my left hand (despite of
being right-handed), so left-hand usability is usually an important factor when
choosing a mouse.

<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/posts/img/mouse_fixing/side_buttons.jpg" markdown="1"/>
    Left side of the device, with the G4 and G5 buttons visible, and the
    plastic cover in place of where the G6 button should be.
</div>

I would say the G502 X is usable with my left hand, though it is surely not the
most left-hand friendly model I have had. The G4 and G5 side buttons are usable
with my ring finger, though not as conveniently as other mice due to the top
surface and the G7 and G8 buttons protruding to the left. The G6 button was too
inconvenient and would end up being clicked by accident too often to be useful.
Thankfully it is a removable button, held in place by a magnet, and so I
quickly decided to uninstall it and put the provided cover piece in its place.

The G7 and G8 buttons feel also easy to accidentally click with my left middle
finger, but not as much as the G6 button.

# Internal design

When taking the mouse apart to reach the scroll wheel I was a bit surprised by
its internal complexity. Clearly a lot of engineering design went into it.

The device has three PCBs and so many screws that it took over half an hour to
take it apart. Surely it has come a long way since all you needed to fully take
apart a (rolling-ball) mouse was to remove three or four screws on the bottom,
and that was it.

<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/posts/img/mouse_fixing/parts.jpg" markdown="1"/>
    That is a lot of parts.
</div>

The battery is easy to replace, only needing to open the bottom. I only wish
the bottom screws were not hidden under the pads, as it requires to remove the
latter and risk damaging them in the process. In my case I managed to do that
without causing too much wear on them, but this is a good example of putting
aesthetics over functionality, especially considering the bottom of the mouse
is already out of sight during normal use, so having a few visible screws on
the bottom is far from being a real aesthetic problem to begin with.

Reaching the scroll wheel, on the other hand, requires to remove the middle
panel and disassemble the buttons.

<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/posts/img/mouse_fixing/screws.jpg" markdown="1"/>
    Can you count how many screws are there?
</div>

Sometimes the disassembly shows how the design has been pushed and optimized,
for instance one of the screws needs to be reached through a hole on the top
PCB, and only after removing an FFC (flexible flat cable) from its socket.
Getting to it requires a long and thin screwdriver, and only one of the
screwdrivers in my set made it (barely).

<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/posts/img/mouse_fixing/screw.jpg" markdown="1"/>
    Reaching this one screw takes some effort.
</div>

After taking out the top of the case and taking apart the middle panel to reach
the upper PCB, it is finally possible to remove the scroll wheel assembly. That
is when we reach the tricky part that inspired me to write this post, as there
are two small springs balancing the scroll wheel assembly above the
middle-button switch. Those two springs are neither glued nor fixed to the
frame in any way, and they will jump out when uninstalling the scroll wheel
assembly. I was not aware of it and I almost lost one of them, but thankfully
it did not fall off my desk and I was able to find it after some search effort.

<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/posts/img/mouse_fixing/springs.jpg" markdown="1"/>
    The two springs balancing the middle button click.
</div>

# Scroll wheel replacement

Thankfully, replacement parts are easy to find and not too outrageously
expensive.[^7]

<div class="center-block"
     style="width: 60%; text-align: center; font-size: 80%;">
    <img src="/posts/img/mouse_fixing/wheels.jpg" markdown="1"/>
    Original scroll wheel assembly (left) and replacement part (right).
</div>

The first and most noticeable difference between original and replacement is
its weight. The replacement part is significantly heavier, highlighting how
much effort has been put into minimizing the weight of the G502 X, with its
lightness being one of the main advertisement points over its predecessor G502.

I personally do not mind a few grams difference, and if anything I like the
extra momentum from the additional weight on the wheel itself, especially when
scrolling in unlocked mode. If the weight bothered me, I could try installing
the old wheel in the new assembly[^8] and see if that still fixes the problem
while retaining the lighter weight, but for now I am not concerned enough to
even consider the option.

A second noticeable difference is how the wheel brake is lighter on the new
wheel, giving it a longer stopping time when the wheel is in locked mode.[^9]
This contrasts with how the original wheel would immediately stop upon lifting
the finger while scrolling in locked mode. I am pretty sure this could also be
changed by tweaking (or replacing) the spring controlling the brake, but I
personally do not mind the difference for now.

# Some inspiration

This little adventure had the side effect of making me reflect about ergonomics
of the scroll wheel. Especially noticing how tiresome for the finger it was to
turn the faulty wheel[^10] and afterwards thinking about the length and depth
of the flexing movement required to operate a scroll wheel, even when the wheel
itself rolls as smoothly as it gets.

When it comes to ergonomics, it is important to both minimize movement and
minimize the amount of force needed in each movement, to reduce strain on both
muscles and joints that can have negative effects in the long run.

All of this made me consider the idea of mapping the G7 and G8 buttons to
scroll up and down and use them in place of the scroll wheel, as they require
so much less effort to operate. Or possibly to remap the left and right tilt on
the scroll wheel to instead scroll up and down. Or a combination of both (maybe
for fast and slow scroll respectively).

I am not sure how discrete clicks or click-and-hold will feel when compared to
the continuous motion of a wheel, but it will be interesting to see how easy or
hard it is to adapt to it and how effective it will feel.

# Footnotes
{:footnotes}

[^1]: Surprisingly enough, the first requirement of having USB-C connector was
      unexpectedly hard to fulfill at the time, a surprising number of high-end
      models were still using USB Micro-B.

[^2]: On the flip side, the charging mat is more expensive than a Qi charger
      and not interoperable with other brands, implying a certain level of
      commitment to the brand and customer lock-in, of which I am not a fan.

[^3]: To be fair, I use the mouse relatively little as most of my interaction
      with computers goes through the keyboard, but when it comes to health I
      will take all the help I can.

[^4]: I do not want to use one-use replaceable batteries due to their
      environmental unfriendliness, even after ignoring the cost and the
      annoyance of keeping them in stock at home and replacing them when needed.

      On top of that, I do not want to be bothered by having to keep an eye on
      the charge level of rechargeable batteries and have to charge them. Qi
      wireless charging pads make the process simpler (for models that support
      it), but they still require some active awareness from the user.

      An extra benefit of this charging method is that the battery can be
      charged while in use, which should hopefully help when the battery ages.
      And the possibility of using the mouse over a USB cable acts as a final
      fallback, even if the internal battery where to die and I could not find
      a replacement part.

[^5]: So not long after expiration of the two-year legal warranty.

[^6]: I am sure it is not a matter of friction on the axle, and that nothing
      got stuck in between the wheel and its housing.

[^7]: Still more expensive than I would think, but at least not bad when
      compared to the price of the mouse itself.

[^8]: As I suspect the problem is likely with the assembly case rather than
      with the wheel itself.

[^9]: I assume this is also due to the additional weight on the replacement
      wheel, requiring more force to halt it.

[^10]: To the point that I had to put aside my G502 X and use an old spare
       mouse until the issue was fixed. Thankfully the replacement part was
       delivered in just one week.
