---
title: "My first iOS app with RubyMotion in 2015"
date: 2015-08-23 15:37 UTC
tags: rubymotion, ruby, ios, tune fork, redpotion, promotion
change_frequency: never
ogp:
  og:
    description: "My first iOS app with RubyMotion in 2015"
    title: "My first iOS app with RubyMotion in 2015"
    url: 'read/my-first-ios-app-with-rubymotion-in-2015'
---

So, I've taken to learning RubyMotion specifically to make iOS applications.  This blog is all about my experience as a fresh iOS developer with no prior experience with Objective C or Swift.  I'll go through the benefits, the bottlenecks and what I intend to do in the future.

Here's a screenshot of my App. It's a very simple guitar tuner called Tune Fork. For anyone that doesn't play guitar, the strings occasionally need tuning and some songs need playing in different tunings, too.  This app's purpose is to make tuning easier. It's certainly not a unique app. Similar apps exist, but I felt it was a reasonably simple app to make for my skill level.

<img class="gfyitem" data-id="NiftyCreativeDutchsmoushond" style="margin-left:auto;margin-right:auto;"/>

There are 3 tabs: 

* The tuner, which plays the notes out loud
* The profiles tab, which lets you select or create custom tunings.
* The settings tab, which adds some minor customisations to the tuner.

RubyMotion is comparable to Ruby, with the added project generator and various rake tasks for compiling and testing out of the box.  These are useful, but I had no prior experience with iOS development and I spent most of my time reading books and watching screencasts on how to use it.

I really wish that RubyMotion came with _more_ documentation and _more_ handholding for beginners. The getting started guide consists of basic terminology, installation, a list of recommended text editors and a "Hello World" application for iOS and OSX. I appreciate that there are a lot of samples but for a paid programming language I expect more documentation.

[MotionInMotion](http://motioninmotion.tv) has some incredible screencasts that really made RubyMotion click for me, especially the RubyMotion for Rails Developers series. It's disappointing that FluffyJack seems to have stopped making them. Considering it costs $9/month and boasts a "New Episode Every Monday" - as of now (August 22nd, 2015) there hasn't been a screen cast since April 7th. That's a lot of missed Mondays! His book, RubyMotion for Rails Developers, which I preordered, also appears to be abandoned, with no sign of updates since the initial sample chapter.

[Motion Toolbox](http://motion-toolbox.com/) is a simple website that helps you find gems. It leaves a lot to be desired if, like me, you don't really know what you're looking for. Categories are cool and all but having a text search like [RubyGems](https://rubygems.org), [NPM](https://packagist.org/) or [Packagist](https://packagist.org/) would be more useful.

There are a lot of gems out there that try to hide the cruft of Objective C which leaks through to RubyMotion. ProMotion, MotionKit, Sugarcube, RMQ, Bubblewrap, MotionPrime... the list goes on.  You would think that this is a good thing; however, as a beginner it's quite overwhelming. Some of these gems have overlapping responsibilities it's difficult to know which combinations to use.

The RedPotion gem makes this a non-issue. RedPotion glues a few of these gems together.  Namely, ProMotion and RMQ, as well as other useful gems. It has detailed documentation to get you started. It also comes with a lot of useful generators and a sensible directory structure. It's essentially Rails for  RubyMotion.

If RedPotion is Rails then RMQ is jQuery. As quoted from their Github, "fast, non-polluting, chaining, front-end library. It’s like jQuery for RubyMotion plus templates, stylesheets, events, animations, etc.".  My favourite feature of this gem is the live stylesheet reloading which allows editing the styles without recompiling the application - a huge time saver!

With the documentation from all of the gems that RedPotion brings you can get a surprising amount of work done. Problems arise when you want to steer away from the happy path, though. For example I wanted to change a significant amount of the colour scheme of my app and with certain elements it can be very awkward.  Along side a lot of Googling, [Reveal](http://revealapp.com) and the Sublime Text Plugin [SublimeObjC2RubyMotion](https://github.com/kyamaguchi/SublimeObjC2RubyMotion) have been incredibly useful.

The majority of problems can be solved with Google but it's very rare to see an answer in RubyMotion. It's a shame, but I don't feel pretending Objective C or Swift don't exist is a viable option. I may end up reading one or two books on iOS development in Swift in the future, as I believe it would be hugely beneficial. I fear there will never be a time when I can Google a question and assume that the answer is already available in RM.

In terms of community RubyMotion has the disadvantage of the added cost. This steers a significant amount of people away from RM but the people that _are_ there are very helpful and fast to respond to any questions. 

I'd like to see a way to encourage programmers from other CLI driven languages to pursue RubyMotion. Node, [Modern] PHP, Python developers etc. As far as I'm aware there is no alternative in those languages. Although they may not know Ruby they still might enjoy the workflow that RubyMotion and RedPotion bring.

In summary, RubyMotion is far from perfect, but if you prefer the "webdev" workflow of CLI generators, REPL and using your preferred text editor I think it's worth a shot - especially with the RedPotion gem. Aside from a few hiccups, it's quite enjoyable to use. I know that I would never have made my first app if RubyMotion and RedPotion didn't exist so I'm quite pleased that I gave it a go.
