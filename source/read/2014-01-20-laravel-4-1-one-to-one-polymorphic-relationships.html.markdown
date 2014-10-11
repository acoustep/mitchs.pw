---
title: Laravel 4.1 one-to-one polymorphic relationships
date: 2014-01-20 00:00 UTC
tags: Laravel 4.1, Laravel, PHP, Eloquent
---

To use one-to-one polymorphic relationships in Laravel 4.1  use the "morphOne" method in your models.

For example: I have two tables, pages and products.  I want to be able to add one featured image to each of these.

The Product model would look like this:

```php
<?php
class Product extends Eloquent {
	public function image() {
		return $this->morphOne('FeaturedImage', 'imageable');
	}
}
```

The Page model would be:

```php
<?php
class Page extends Eloquent {
	public function image() {
		return $this->morphOne('FeaturedImage', 'imageable');
	}
}
```

READMORE

For the FeaturedImage table you would need to columns ```imageable_id:integer``` and ```imageable_type```.

Then in your FeaturedImage model you can have:

```php
<?php
class FeaturedImage extends Eloquent {
	public function imageable()
	{
			return $this->morphTo();
	}
}
```

This will allow you to use polymorphism on one-to-one relationships
