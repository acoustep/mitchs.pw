---
title: Making moderation easy
date: 2015-04-06 09:27 UTC
tags: Laravel, Laravel 4.2, Eurekar, Moderation
change_frequency: never
ogp:
  og:
    description: ""
    title: 'Making moderation easy'
    url: 'read/making-moderation-easy/'
---

For just over a year I've been working on a website called [Eurekar](http://eurekar.co.uk). To describe it briefly, it's a cool little website which has news articles for cars, a fairly complex article search and another search for UK car dealerships.

I have built an insane amount of content management systems in Laravel but what makes Eurekar unique is that the content is pulled from an external XML feed rather than created first hand in the CMS.

READMORE

My first thoughts that were that having the content brought in from an external system would make things easier.  If the content is made elsewhere then there is no need for an administration area. Unfortunately, due to the feed being out of my control the opposite is true and moderation has become more crucial than ever.

Some of the hurdles this brings include:

* Keeping the website's content up to date with the feed.
* XML data not having the ideal structure.
* Difficulty importing certain characters from the XML into MySQL.
* Parsing XML data in general.

There is two other issues that were by the far the most difficult to deal with. 

1. We often get articles with the same images because different authors can write articles about the same cars.  Because of this they use same press release images.  It can look silly having the same thumbnail show up 2-3 times in a list of articles so it's important that they show different images.
2. On a similar note, on certain pages such as the home page we didn't want multiple articles showing for the same cars so as to show a wider variety.

As all of these issues cropped up it gradually became clear that being able to moderate the website easily was incredibly important.

## Editing Article Content

The XML feed is fetched every 30 minutes with a cron job that uses PHP's SimpleXML extension to parse it.  We have to run a bunch of character replacements on this feed so that we don't get any issues with certain symbols. Even with this in place the £ symbol occasionally manages to elude me which is why I wanted editing articles to be incredibly quick and simple.

If you take a look at this page as an example [Mercedes scores a triple](http://eurekar.co.uk/articles/2015-04-03/mercedes-scores-a-triple) Below is a screen shot of how it looks when logged in as an administrator.

![Quick edit](http://i.imgur.com/EvJxSGp.png)

On the left side there are 2 buttons: Quick Edit and Full Edit.  Full Edit takes you to the admin area for editing all of the content of the article. Then there's quick edit which uses jQuery to bring up the right side of the image. Here a user can edit the title and the content on the same page which is perfect for fixing minor grammatical errors.  The save button returns the administrator back to the normal page after the content is updated.

## Editing Image Order

Very often an image of a car boot gets uploaded first from the feed and therefore becomes the image that shows up on all of the article thumbnails.  Obviously this isn't ideal. A car boot is not what our readers are initially interested in.  What make matters more difficult is that articles sometimes have the same images and we wanted to avoid showing duplicates images on pages which listed articles.

There are two parts to this solution. The easiest part was allowing administrators to reorder images.

![Image reorder](http://i.imgur.com/1TCGmuD.png)

The above screenshot is how the image gallery looks as an administrator.  The green button uses HTML5 drag and drop to sort image ordering and is updated via an AJAX request when an image is dropped from the mouse drag.  The pause button toggles the image being viewable as a thumbnail on a list of articles (I'll get to why this is important in a moment).  The bin button deletes the image entirely which is useful when a low quality image is uploaded.

Now to the more challenging problem: preventing duplicate images from being  shown on a list of articles.  Eurekar has many sections which list articles. Some articles might have the same preferred first image (If the images came from the same press release) but they may not always appear in the same sections.  

In an ideal situation the next article which wants to use the same image needs to skip to the next image in it's gallery.  This is why image reordering and the pause toggle button from earlier are important.  This is how we can make sure the best images get rotated on the website.

This is probably the most irregular code I've had to create in Laravel and in honesty I am not 100% happy with how I implemented it. Here's a snippet of code which generates JSON for our "View More"  AJAX requests. This code sits in a repository and is called by methods for different sections of the website.

```php

<?php
protected function generateJSON($articles, $hide_from)
{
  $c = new \Illuminate\Database\Eloquent\Collection;
  $image_index = 0;
  $used_images = [];
  foreach($articles as $article) {
    foreach($article->images as $image) {
      if(in_array($image->filename, $used_images)) {
        $image_index++;
      } else {
        $used_images[] = $image->filename;
        break;
      }
    }
    if($image_index >= $article->images->count()) {
      foreach($article->images->slice(0, $image_index) as $image) {
        if($key = array_search($image->filename, $used_images) !== false) {
          unset($used_images[$key]);
        }
      }
      $image_index = 0; 
    }
    $blurb = word_slice($article->content, 490);
    $c->add([
      'id' => $article->id,
      'title' => $article->title,
      'slug' => $article->slug,
      'url' => route('articles.show', $article->slug),
      'content' => $article->content,
      'blurb' => $blurb,
      'published_at' => $article->published_at->toDateTimeString(),
      'filename' => $article->images[$image_index]->filename,
      'full_image' => Config::get('assets.aws').Config::get('assets.image-medium').$article->images[$image_index]->filename,
      'thumbnail' => Config::get('assets.aws').Config::get('assets.image-small').$article->images[$image_index]->filename,
      'hide_from' => $hide_from,
    ]);
  }
  return [
    'total' => $articles->getTotal(), 
    'from' => $articles->getFrom(),
    'to' => $articles->getTo(),
    'articles' => $c->toArray(),
  ];
}
```

A paginated collection of articles is passed through to the method as well as a second paramater which isn't important to this problem - it is just a value which I need to pass to the JSON.

On line 4 I made a custom collection with ```\Illuminate\Database\Eloquent\Collection``` which is going to hold all of the data for the JSON API.

On lines 5-6 I've initiated 2 variables: ```image_index``` and ```used_images``` which will be a list of images that have been used so that I can keep track of when I need to show a the next image.

Through lines 7-38 I'm looping through all of the articles and then looping through every image in each article. If the image exists in the ```used_images``` array then I skip to the next image.  If it doesn't exist then I add it to ```used_images``` and break the images loop.

The next if statement checks if the ```image_index``` is more than the amount of images available. This means there's no more images left to go through so I use ```array_search``` to remove all of the current articles images from the ```used_images``` array and set the index back to the beginning. This resets the images used for a certain selection and allows them to be rotated through again.

After all that hard work all that's left is to add the article, its main image and a few other useful attributes to the custom collection which will then be sent off as a JSON response.

## Editing article listings

Lastly we wanted to be able to show more variety on certain pages of the website. This problem arose due to author's releasing articles about the same car at the same time. Meaning we occasionally get 3 Suzuki Celerio articles hogging the front page which isn't ideal.  The only circumstance where we want 3 or more Suzuki Celerios to show in a list of articles is if a user searched for that car model specifically.

My solution for this is to have hide buttons for each article in an article list.  Take for example the home page latest news shown below:

![Hiding news](http://i.imgur.com/XTul45t.png)

Each section of the website has a boolean field which dictates whether it can be shown on its page. When hide is pressed in a section then it can no longer be in the article listing for that section. There is a separate admin page to revert this change incase of hider's remorse.

## Final Thoughts

There's a lot of work that goes into making a good admin area and what I've shown you is just a tiny glimpse of the overall system.

I realise there is a severe lack of code in this article but I hope that you've  at least found it insightful and that I've given you some ideas to work in to your own systems.

