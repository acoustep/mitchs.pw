---
title: Automating Configurations with Laravel
date: 2013-08-07 00:01 UTC
tags: Laravel, Laravel 4
change_frequency: never
ogp:
  og:
    description: 'One of my favourite features of Laravel is how it handles configurations for different environments.  You can have different settings for development, staging, beta, production and even separate configurations for each developer working on the project.'
    title: "Automating Configurations with Laravel"
    url: 'read/automating-configurations-with-laravel'
---

One of my favourite features of Laravel is how it handles configurations for different environments.  You can have different settings for development, staging, beta, production and even separate configurations for each developer working on the project.

With a fresh version of Laravel installed: take a look at the ```app/bootstrap/start.php``` file.  Near the top of the file you should see the following snippet of code:

```php
<?php
$env = $app->detectEnvironment(array(
	'local' => array('your-machine-name'),
));
```

Within the ```detectEnvironment()``` method you can define an array of configurations.

If you and a friend or coworker are working on a project and using Git to keep track of changes you could use the following:

```php
<?php
$env = $app->detectEnvironment(array(
	'mitch' => array('mitch-machine-name'),
	'tom' => array('tom-machine-name'),
));
```

Laravel will detect which configuration to use from your computer's hostname.

READMORE

### Finding your Hostname

To get your machine's name go in to the command prompt and enter ```hostname```.  The output should be your computer's hostname put this in your array.  

If you want to use the same settings across multiple computers you can add multiple values to the second array like so:

```php
<?php
$env = $app->detectEnvironment(array(
	'development' => array('mitch-machine-name1', 'mitch-machine-name2'),
));
```

### Editing your New Configurations

The key of the array corresponds with the name of a folder.  In my case I would add a ```development/``` folder within ```app/config/``` to become ```app/config/development/```.  Any files or settings you put in here will override the default settings!

Copy your ```app/config/database.php``` to ```app/config/development/database.php```.  Now any settings you change in this new file will be used on your machine.  

It's a little unnecessary to include the whole ```database.php``` again.  With Laravel we can pick and choose which settings we want to update as simply as this:

```php
<?php
return array(

	'connections' => array(

		'sqlite' => array(
			'driver'   => 'sqlite',
			'database' => __DIR__.'/../database/production.sqlite',
			'prefix'   => '',
		),

		'mysql' => array(
			'driver'    => 'mysql',
			'host'      => 'localhost',
			'database'  => 'database',
			'username'  => 'root',
			'password'  => '',
			'charset'   => 'utf8',
			'collation' => 'utf8_unicode_ci',
			'prefix'    => '',
		),

		'pgsql' => array(
			'driver'   => 'pgsql',
			'host'     => 'localhost',
			'database' => 'database',
			'username' => 'root',
			'password' => '',
			'charset'  => 'utf8',
			'prefix'   => '',
			'schema'   => 'public',
		),

		'sqlsrv' => array(
			'driver'   => 'sqlsrv',
			'host'     => 'localhost',
			'database' => 'database',
			'username' => 'root',
			'password' => '',
			'prefix'   => '',
		),

	),
);
```

Notice how the only settings I'm returning in the whole of ```database.php``` are the ```connections```.  That's because I want everything else to use the default settings!

### Final Laravel configuration example

At the beginning of this blog I mentioned that you could have a configuration for development, staging, beta, production.  Well just as a reference here's an example of what it would look like!

```php
<?php
$env = $app->detectEnvironment(array(
    'development' => array('your-machine-name', 'your-second-machine-name'),
    'staging' => array('staging-machine-name'),
    'beta' => array('beta-machine-name'),
    'production' => array('production-machine-name'),
));
```

I hope you found this blog useful! For more information on Laravel configurations make sure to check out the [documentation](http://laravel.com/docs/configuration)
