---
title: Simple Search with Laravel and ElasticSearch
date: 2015-01-05 19:29 UTC
tags: Laravel, Laravel 4.2, ElasticSearch, ElasticSearch 1.4, PHP, Search
published: false
---
I was recently asked to make a search engine for a client's website. Normally I would go down the MySQL fulltext search route but I was feeling rather adventurous at the time.  I had no experience with ElasticSearch, Apache Solr or any other search system prior to this so I decided to pick ElasticSearch and dive in head first. This tutorial is a result of some of the things I picked up while learning it.

In this tutorial I aim to show you how to set up ElasticSearch with Laravel 4.2 so that you can have a basic website search. You will learn how to set up the [Elasticquent](https://github.com/adamfairholm/Elasticquent) Laravel package and some basic ways to fine tune your search engine.
 
READMORE

## Installing ElasticSearch

If you haven't installed ElasticSearch then make sure you check the [ElasticSearch documentation](http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/\_installing\_elasticsearch.html) for setting it up.

You will also need curl.  Curl comes with Mac and Linux but if you're on Windows you can download it [here](http://curl.haxx.se/download.html).

I also recommend [Postman App](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm?hl=en) if you use Chrome.  Postman will let you run REST commands in a nice GUI rather than using command line.

Confirm that your ElasticSearch instance is running by the following command in your command line

```curl -XPOST 'http://localhost:9200/?pretty'```

You should see a nice prettified json response if everything is working okay.

## Setting up Laravel

Get your Laravel App up and running. If you are unfamiliar see the [Laravel docs on installing](http://laravel.com/docs/4.2/installation) and make sure you have a database set up and ready.

## Generating your database table

I'm going to set up a generic database table with 3 fields: title, content and tags.

```php artisan migrate:make create_posts_table```

In your migration file (located in ```app/db/migrations/<DATETIME>_create_posts_table.php```) use the following code:

```
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;

class CreatePostsTable extends Migration {

	/**
	 * Run the migrations.
	 *
	 * @return void
	 */
	public function up()
	{
		Schema::create('posts', function(Blueprint $table)
		{
			$table->increments('id');
			$table->string('title');
			$table->text('content');
			$table->string('tags');
			$table->timestamps();
		});
	}


	/**
	 * Reverse the migrations.
	 *
	 * @return void
	 */
	public function down()
	{
		Schema::drop('posts');
	}

}
```

Do a migration and then we'll move on to installing some third party packages.

```php artisan migrate```

## Packages

I'll be using 2 packages in this tutorial, Elasticquent and Faker.  You can ignore faker if you plan on importing your own data. For the sake of the tutorial I'll include it.

Open your composer.json and add the following to the ```require``` object:

```
"fairholm/elasticquent": "1.0.*",
"fzaninotto/Faker": "1.4.*"
```

Run ```composer update --prefer-dist``` and we'll start start generating some  dummy data!

## Dummy data (optional)

Create ```app/database/seeds/PostsTableSeeder.php``` and add the following code

```
<?php 

class PostsTableSeeder extends Seeder {


    public function run()
    {
        // Remove any existing data
        DB::table('pages')->truncate();

        $faker = Faker\Factory::create();
        
        // Generate some dummy data
        for($i=0; $i<30; $i++) {
          Post::create([
            'title' => $faker->sentence(3),
            'content' => $faker->paragraph(5),
            'tags' => join(',', $faker->words(5))
          ]);
        }
    }

}

```

Run ```php artisan db:seed --class="PostsTableSeeder"``` in your command line. You should now have plenty of test data to work with!

## Setting up Elasticquent

## Fine-tuning your search
