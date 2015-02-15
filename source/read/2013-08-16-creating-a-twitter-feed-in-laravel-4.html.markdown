---
title: Creating a Twitter Feed in Laravel 4
date: 2013-08-16 00:00 UTC
tags: Laravel, Laravel 4, Twitter, PHP
change_frequency: never
ogp:
  og:
    description: 'In this tutorial I aim to show three things: How to get Twitteroath working with Laravel 4. How to create and access a new configuration file for your twitter settings. How  to create a  helper method for your tweets'
    title: "Creating a Twitter Feed in Laravel 4"
    url: 'read/creating-a-twitter-feed-in-laravel-4'
---

*This tutorial is now out of date - checkout [philo/laravel-twitter](http://packalyst.com/packages/package/philo/laravel-twitter) or [thujohn/twitter](http://packalyst.com/packages/package/thujohn/twitter) for an easier and more up to date solution.*

In this tutorial I aim to show three things

* How to get Twitteroath working with Laravel 4
* How to create and access a new configuration file for your twitter settings
* How  to create a  helper method for your tweets

To start off install [twitteroath](https://github.com/abraham/twitteroauth) via composer.

Put line 4 in your ```composer.json``` with the rest of the Laravel Composer set up and run ```composer update``` or ```composer install``` if you haven't already

```javascript
{
	"require": {
		"laravel/framework": "4.0.*@dev",
		"abraham/twitteroauth": "dev-add-composer-json"
	},
	"autoload": {
		"classmap": [
			"app/commands",
			"app/controllers",
			"app/models",
			"app/database/migrations",
			"app/database/seeds",
			"app/tests/TestCase.php"
		]
	},
	"scripts": {
		"post-update-cmd": "php artisan optimize"
	},
	"minimum-stability": "dev"
}
```

READMORE

While that's running head over to [dev.twitter.com](http://dev.twitter.com) and sign in with your Twitter account.  If you haven't already made consumer tokens and access tokens now is the time to do so!

## Making access and consumer tokens

Go to my applications, create a new application and fill in the details.  After you create your application you will be asked if you want to create an access token from your Twitter account.  Make sure you do it!

After that's done you can view your applications details by going to My applications.  

![My Applications](http://i.imgur.com/RyVJMq5.jpg)

Click on your newly created application and take note of your Consumer key, Consumer secret, Access token and Access token secret.

Now in your Routes you should be able to do the following
```php
Route::get('/', function()
{
$connection = new TwitterOAuth('consumer\_key', 'consumer\_secret', 'access\_token', 'access\_secret\_token');
	$tweets = $connection->get("https://api.twitter.com/1.1/statuses/user\_timeline.json?screen\_name=TWITTER\_ACCOUNT\_NAME&count=2");
return json_encode($tweets);
});
```

Going to your applications route should show your tweets in JSON format now - however, I hardly find this organization in the spirit of Laravel so let's clean it up a little!

## Creating and accessing a new configuration file

Within ```app/config``` create a new file called ```twitter.php``` with the following:

```php
return array(
  'consumer_key' => 'consumer_key_here',
  'consumer_secret' => 'consumer_secret_here',
  'access_token' => 'access_token_here',
  'access_secret_token' => 'access_secret_token_here',
  'twitter_user' => 'mitchartemis'
);
```

Now we can change our ```route.php``` to have the following:

```php
$connection = new TwitterOAuth(Config::get('twitter.consumer_key'), Config::get('twitter.consumer_secret'), Config::get('twitter.access_token'), Config::get('twitter.access_secret_token'));
$tweets = $connection->get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=".Config::get('twitter.twitter_user')."&count=5");
```

Now that's working you might feel that you need to use this multiple times within the application.  Having it in a route or controller method isn't ideal for this.

## Creating a helper method for your tweets

Create a new file called ```helpers.php``` in the```app/``` folder.

Now we can put any functions we want to use more than once in here.  So let's make a simple one for Twitter.

```php
function twitterFeed()
{
	$connection = new TwitterOAuth(Config::get('twitter.consumer_key'), Config::get('twitter.consumer_secret'), Config::get('twitter.access_token'), Config::get('twitter.access_secret_token'));
	$tweets = $connection->get("https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=".Config::get('twitter.twitter_user')."&count=5");

	return $tweets;
}
```

Inside of routes we can now remove the 2 lines of code and use

```php
$tweets = twitterFeed();
```

At this point if you try the code you will most likely not be able to access the ```twitterFeed()``` funtion.  To use we must add it to ```composer.json``` as shown below

```javascript
{
	"require": {
		"laravel/framework": "4.0.*@dev",
		"abraham/twitteroauth": "dev-add-composer-json"
	},
	"autoload": {
		"classmap": [
			"app/commands",
			"app/controllers",
			"app/models",
			"app/database/migrations",
			"app/database/seeds",
			"app/tests/TestCase.php"
		],
		"files": [
			"app/helpers.php"
		]
	},
	"scripts": {
		"post-update-cmd": "php artisan optimize"
	},
	"minimum-stability": "dev"
}
```

Between lines 15-18 I have added the helpers.php to an array with the key of "files".  Now run ```composer update``` and you're all set!

