---
title: Bootstrap 2 pagination in Laravel 5
date: 2015-03-21 15:43 UTC
tags: Laravel, Laravel 5, Bootstrap 2, Twitter Bootstrap
change_frequency: never
ogp:
  og:
    description: ""
    title: 'Bootstrap 2 pagination in Laravel 5'
    url: 'read/bootstrap-2-pagination-in-laravel-5/'
---

I recently had to help port a website that used Twitter Bootstrap 2 to Laravel 5 and discovered that changing the pagination template is completely different in Laravel 5.

READMORE

Thanks to [this StackOverflow thread](http://stackoverflow.com/questions/28240777/custom-pagination-view-in-laravel-5) I came up with this solution.

In short: Laravel 5 makes use of presenter classes to style pagination.

You can put this class wherever you like. It's down to how you structure your project.

In this example I put the class in a file named ```BootstrapTwoPresenter.php``` which lives inside of a newly created ```app/Presenters``` directory.

The class inherits from Laravel 5's ```BootstrapThreePresenter``` because Bootstrap 2 and Bootstrap 3 pagination are very similar.

```php
<?php namespace App\Presenters;
 
use Illuminate\Pagination\BootstrapThreePresenter;
 
class BootstrapTwoPresenter extends BootstrapThreePresenter
{
  public function render()
  {
    if( ! $this->hasPages())
      return '';

    return sprintf(
      '<div class="pagination"><ul>%s %s %s</ul></div>',
      $this->getPreviousButton(),
      $this->getLinks(),
      $this->getNextButton()
    );
  }
}
```

In your views you can insert the new class into the ```render``` method for the desired results.

```php
{!! $users->render(new App\Presenters\BootstrapTwoPresenter($users)) !!}
```

If you wish to customise the pagination further then the following methods are available to override.


```php
<?php namespace App\Presenters;
 
use Illuminate\Pagination\BootstrapThreePresenter;
 
class BootstrapTwoPresenter extends BootstrapThreePresenter
{
  public function render()
  {
    if( ! $this->hasPages())
      return '';

    return sprintf(
      '<div class="pagination"><ul>%s %s %s</ul></div>',
      $this->getPreviousButton(),
      $this->getLinks(),
      $this->getNextButton()
    );
  }

  protected function getDisabledTextWrapper($text)
  {
    return '<li class="disabled"><a href="#">'.$text.'</a></li>';
  }
  protected function getActivePageWrapper($text)
  {
    return '<li class="active"><a href="#">'.$text.'</a></li>';
  }
  protected function getDots()
  {
    return $this->getDisabledTextWrapper('&hellip;');
  }
}
```
