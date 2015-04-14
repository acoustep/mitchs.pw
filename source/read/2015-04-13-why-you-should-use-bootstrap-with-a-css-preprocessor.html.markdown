---
title: Why you should use Bootstrap with a CSS Preprocessor
date: 2015-04-13 00:00 UTC
tags: Bootstrap, CSS, SASS
change_frequency: never
ogp:
  og:
    description: "why you should use bootstrap with a css preprocessor"
    title: 'Why you should use Bootstrap with a CSS Preprocessor'
    url: 'read/why-you-should-use-bootstrap-with-a-css-preprocessor'
---

It's all too easy to import Twitter Bootstrap from [BootstrapCDN](http://www.bootstrapcdn.com/), overwrite the styles in your own CSS and just stick an ```!important``` on anything that doesn't work the first time you try to change it.  

Using a preprocessor such as SASS lets you make these changes in a much easier and more organised fashion.

Say for instance that you wanted to change the background colour for the Bootstrap class ```btn-primary```. What you would need to do is go to the [customise](http://getbootstrap.com/customize) section of the Bootstrap documentation, scroll down to [buttons](http://getbootstrap.com/customize/#buttons) and find the variable(s) that are used to set ```btn-primary```'s styles.

For this example ```@btn-primary-border``` and ```@btn-primary-bg``` would be what you need to change.  Since I use SASS I need to switch out the ```@``` for ```$```.  Then I put the new value above ```@import "bootstrap";``` in my ```app.scss```.

```scss
$btn-primary-bg:#ff0000;
$btn-primary-border: darken(#ff0000, 5);
@import "bootstrap";
```

This goes for everything else as well. The navigation bar, alerts,  background colour, grid margin etc.  It's also much more convenient than overriding them in a separate stylesheet. It's also faster than using the Bootstrap website's customiser because you have the option to adjust them to your preference very quickly.

Another major benefit is that you can extend these Bootstrap classes and make your own!  Perhaps you want another button class called ```btn-help``` which will look slightly different to ```btn-info```.

It's as simple as using SASS's ```extend``` and then overriding the properties you want to change.

```scss
.btn-help {
	@extend .btn-help;
	background-color: lighten($btn-info-bg, 5);
}
```

I could go on about the benefits of SASS and LESS.  Hell, even Stylus has a [Bootstrap port](https://github.com/maxmx/bootstrap-stylus)!  There is one last thing that I'd like to mention and that's organisation.

I have found from own experience that sticking all of your CSS into one file is a recipe for a disaster.  Yes, you could split your stylesheets into separate files and include them separately, or have a Grunt/Gulp task that minifies them but if you're going that far you may as well let a preprocessor do it for you while giving you it's other benefits.

If you are using one CSS file then consider this: When you first make your website you may place all of the code in neat groups that make logical sense.  Then one Friday at 5 o' clock you need to fix a bug that your boss just noticed.  You quickly add a fix to the bottom of your stylesheet.  It's not a big deal but suddenly your header CSS is in two different places. Little things like this add up, and the more of it you have, the more difficult it becomes to reorganise.

Right now I'm using [BEMSMACSS](https://gist.github.com/bensmithett/4736571) to organise my CSS. But I've also added a ```_shame.scss``` file which I first heard about from [The Changelog Podcast](https://thechangelog.com/shame-css/). 

The idea behind a ```shame.css``` is to add any CSS that needs to be done in a rush, or using CSS hacks to fix something that you can't quite figure out. This isolates them and lets you or a team member come back to them later. The name ```shame.css``` really encourages you to fix the content.  I think it's a genious idea because it's so simple yet effective.
