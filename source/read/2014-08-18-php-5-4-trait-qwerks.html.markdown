---
title: PHP 5.4 Trait Qwerks
date: 2014-08-18 20:06 UTC
tags: PHP, PHP 5.4, Traits
---

Although the title may lead you to think otherwise;  I actually really like Traits.  I wish I had made the switch to 5.4 sooner! Bundle them with the shorter array syntax and I'm a happy PHP dev.

I recently experimented with Traits in a Laravel package. You can find the package here [DatController](https://github.com/acoustep/dat-controller)

This blog is contains a couple of the not-so-obvious points of traits which I came accross.

#### You can not override trait properties

I think this is what I like the least about traits.  You can not set a default property and have a class override it.

```php
<?php
trait NewTrait {
	public $variable = 'default value';
}

class NewClass {
	use NewTrait;
	
	public $variable = 'override value';
}
```

I would love to be able to override trait properties. However, you could argue that it's best to use inheritence for these situations.

READMORE

#### You can not use two traits that both require the use the same trait.

This one is a little more tricky to explain.

As an example say you have the following set up:

* BaseTrait - a trait with core methods that you want included in all your other traits.
* CreateTrait - a trait dedicated to a create method.
* UpdateTrait - a trait dedicated to a update method.
* ResourceTrait - a trait which includes CreateTrait, UpdateTrait, DestroyTrait etc so that a developer doesn't have to include them all seperately.

```php
trait BaseTrait {
	public function base_method()
	{
	}
}

trait CreateTrait {
	use BaseTrait;
	public function create()
	{
	}
}

trait UpdateTrait {
	use BaseTrait;
	public function update()
	{
	}
}

trait ResourceTrait {
	use CreateTrait;
	use UpdateTrait;
}
```

Because both CreateTrait and UpdateTrait include the BaseTrait you will receive the following error:

```php
Trait method base_method has not been applied, because there are collisions with other trait methods on ResourceTrait
```

Even though it's the exact same method it will create a collision.

That's all for now.  I definitely want to use traits more in PHP but I do feel they are quite restrictive in some situations.
