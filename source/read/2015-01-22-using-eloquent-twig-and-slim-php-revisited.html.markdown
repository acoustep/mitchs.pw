---
title: Using Eloquent, Twig and Slim PHP - Revisited
date: 2015-01-22 21:27 UTC
tags: Slim, Twig, Eloquent, PHP, microframework, slim-twig-eloquent, Phinx, console, gulp
change_frequency: never
---

It’s been about one and a half years since I made my blog post [Using Eloquent, Twig and Slim PHP](http://fullstackstanley.com/read/using-eloquent-twig-and-slim-php) and a lot’s changed since then but I still love using these three tools for small websites.

You can view all the code for this post [here](https://github.com/acoustep/slim-twig-eloquent) or if you’re looking for the original code from 2013 please switch to the 1.0 release.

READMORE

## What’s changed?

### Migrations
The main update to the repo is migrations.  I’ve added [robmorgan/phinx
](https://github.com/robmorgan/phinx) because i’ve found nothing better outside of Laravel.  I did use [ruckus/ruckusing-migrations](https://github.com/ruckus/ruckusing-migrations) for the longest time but switched because I was unsatisfied with setting up a sensible and simple configuration. In fairness, it’s been a while since I’ve used it and it may have improved since then.

### Gulp, SASS and Coffeescript
I use SASS and Coffeescript for all of my new projects.  They are easy to remove/ignore if you don’t wish to use them. I’ve also added LESS support just because Gulp makes it so simple.

### Console commands
I find myself creating commands for automation fairly often these days. Due to Symfony/Console already being a dependency I thought I may as well include it with a couple of commands out of the box.

```php ste serve```

This is just a wrapper around PHP’s built-in local server. I am always googling the arguments for it so I thought I’d just create a shorter command for convenience.

```php ste model:make```

This command takes one argument: your model’s name. It then generates the file for you and runs ```composer dumpautoload``` so you don’t have to worry about it.

### Structure

The structure is _mostly_ the same. Obviously I’ve added directories for assets.  But I’ve also removed ```app/application.php``` as the current version of Slim no longer requires the extra code.  I’ve also made use of Phinx’s configuration file so you don’t have to update the same variables more than once.

There’s a new directory, ```app/commands```, with the 2 commands mentioned above. This also lets you create your own commands fairly easily for your own automation needs.

### Whoops

[I really like this package](https://github.com/filp/whoops).

## Issues

The biggest issue I had was in fact rather simple to fix.  I was getting no output from ```writeln()``` after requiring ```vendor/autoload.php``` in my console application.  

If there’s one thing that’s worse than a convoluted error message it’s no error message at all.

Whoops ended up being the cause of my woes.  After disabling Whoops for command line I could see exceptions again!

Another issue was unexpected Symfony/YAML behaviour. Turns out that when YAML parser can’t find the required file it just returns a string with the filename.  This took me far longer than I care to admit to figure out.

## Moving forward

As of writing this blog I’ve released an alpha version of the slim-twig-eloquent rewrite and I’m pretty happy with it.  I have a couple of small changes to make and I’d like to write a few tests at least for the command line application.

If there’s one thing about Slim that bums me out it’s how difficult it is to test. I did find a nice package for testing but it’s not compatible with Slim 2.5. I’ve decided to hold off on adding testing for now.

I am also interested in the idea of a separate installer package which would allow you to run ```ste new ProjectName``` and generate a fresh install of the git repo. 

I’ll leave that for another day and another blog post!


