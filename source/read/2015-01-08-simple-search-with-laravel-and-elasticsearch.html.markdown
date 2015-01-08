---
title: Simple Search with Laravel and ElasticSearch
date: 2015-01-08 19:29 UTC
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

Open up your model in ```app/models/Post.php``` (or Create it and add the following):

```
<?php
use Elasticquent\ElasticquentTrait;

class Post extends \Eloquent {
  use ElasticquentTrait;

  protected $mappingProperties = array(
    'title' => [
      'type' => 'string',
      "analyzer" => "standard",
    ],
    'content' => [
      'type' => 'string',
      "analyzer" => "standard",
    ],
    'tags' => [
      'type' => 'string',
      "analyzer" => "stop",
			"stopwords" => [","]
    ],
  );
}

```

On line two we create the Elasticquent Trait shortcut and on line 4 we include it in our class.

Line 6 we add our mapping configuration for ElasticSearch.  You can read more about mappings [here](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping.htmlhttp://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping.html).

Each mapping has a type and an analyzer. Type's can be various data types including strings, numbers and dates.  For now we will stick to the string type but be aware that different types allow you to take advantage of different things including ranges for integers and dates. You can learn more about the types that ElasticSearch supports [here](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-types.html)

The analyzer determines how ElasticSearch stores your data for searching. I've chosen standard for title and content (which can be removed as that is the default) and ```stop``` for tags.  The standard analyzer will remove HTML and grammar and index each word separately.  The stop analyzer can be set to choose which characters split the words for indexing. So as an example take this sentence.

**I love laravel, ElasticSearch and Laravel work well together.**

With a standard analyzer ElasticSearch will create a list like this:

* I
* love
* laravel
* elasticsearch,
* and
* laravel
* work
* well
* together

The stop analyzer that separates commas will group them like this:

* I love laravel
* ElasticSearch and Laravel work well together.

This can be advantagous for phrases you want to priortise search results for.

Ok now we've configured how we want our search to operate it's time to index our database!

Let's use Laravel's REPL to generate our ElasticSearch data. Go to your command line and type ```php artisan tinker```.

Type the following commands

```
Post::createIndex($shards = null, $replicas = null);

Post::putMapping($ignoreConflicts = true);

Post::::addAllToIndex();
```

The first command sets up your index.  An index is sort of like a database table in the ElasticSearch world.

```putMapping()``` takes the mapping properties we set in the model so that ElasticSearch knows how to index all of your data.

```addAllToIndex()``` takes all the data from the database and puts it into ElasticSearch

## Creating the front end

It's up to you to make this pretty/organised. I'll just go through the functionality

Add a route to your ```app/routes.php```

```
Route::get('/', ['as' => 'search', 'uses' => function() {

  // Check if user has sent a search query
  if($query = Input::get('query', false)) {
    // Use the Elasticquent search method to search ElasticSearch
    $posts = Post::search($query);
  } else {
    // Show all posts if no query is set
    $posts = Post::all(); 
  }

  return View::make('home', compact('posts'));
  
}]);
```

Make a template in ```app/views/search.blade.php```

```
<html>
<body>
{{ Form::open(['method' => 'get', 'route' => 'search']) }}

  {{ Form::search('query', Input::get('query', ''))}}
  {{ Form::submit('Filter results') }}

{{ Form:: close() }}

@foreach($posts as $post)
 <div>
  <h2>{{{ $post->title }}}</h2>
  <div>{{{ $post->content }}}</div>
 </div>
@endforeach
</body>
</html>
```

In the above snippet we create a form that allows us to type in a search. Below the form we iterate through either through all of the posts or all of the search results depending on whether the user has searched something.

We may be able to get away with leaving the code as it is for our search. But where is the fun in that? Let's tinker and see how we can improve our search results.

## Fine-tuning your search

Elasticquent has another method called ```searchByQuery()``` which will allow us to specify more details on how we want ElasticSearch to query our data. Here's an example (taken and modified from the Elasticquent docs)

```
$posts = Post::searchByQuery(['match' => ['title' => 'Moby Dick']]);
```

In the above example only the title is searched. You might be wondering how this differs from ```search()``` method behind the scenes. The search() query will match all parameters including our content and tags fields.

If you try searching your data now with text from the content fields you will notice drastically different results.  You may even notice different results when you take data from the title fields, too.  This is because ElasticSearch generates a score from the data it searches. Any relevant text in the fields queried will improve that score.

That's all well and good, but now we want to search our tags because they are the keywords we want to match in the search results. Let's also include content but give it a lower priority.


```
$posts = Post::searchByQuery([
  'query' => [
    'multi_match' => [
      'query' => Input::get('query', ''),
      'fields' => ['title^2', 'content']
    ],
    'match_phrase' => [
      'tags' => Input::get('query', '')
    ]
  ]
]);
```

We can also completely filter out specific terms if they are irrelevent to the search with the terms filter

```
$posts = Post::searchByQuery([
 'filtered' => [
    'filter' => [
      'terms' => ['title' => ['miley cyrus', 'justin bieber']]
    ],
  ],
  'query' => [
    'multi_match' => [
      'query' => Input::get('query', ''),
      'fields' => ['title^2', 'content']
    ],
    'match_phrase' => [
      'tags' => Input::get('query', '')
    ]
  ]
]);
```
Between lines 2-6 we're specifying that when 'miley cyrus' or 'justin bieber' are in the title we want to disregard it from the search.
