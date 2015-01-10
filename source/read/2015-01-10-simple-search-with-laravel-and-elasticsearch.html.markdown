---
title: Simple Search with Laravel and ElasticSearch
date: 2015-01-10 09:00 UTC
tags: Laravel, Laravel 4.2, ElasticSearch, ElasticSearch 1.4, PHP, Search
---
I was recently asked to make a search engine for a client's website. Normally I would go down the MySQL fulltext search route but I was feeling rather adventurous at the time.  I had no experience with ElasticSearch, Apache Solr or any other search system prior to this so I decided to pick ElasticSearch and dive in head first. This tutorial is a result of some of the things I picked up while learning it.

I aim to show you how to set up the [Elasticquent](https://github.com/adamfairholm/Elasticquent) Laravel package and some basic ways to fine tune your search engine.

READMORE

**Note:** This tutorial is aimed at developers who are already familiar with Laravel but are new to ElasticSearch and want some guidance on getting them to work together.

## Installing ElasticSearch

If you haven't installed ElasticSearch then make sure you check the [ElasticSearch documentation](http://www.elasticsearch.org/guide/en/elasticsearch/guide/current/\_installing\_elasticsearch.html) for setting it up. Although not necessary it's worth running through the rest of the getting started guide to understand the basics of how ElasticSearch works.

I also recommend [Postman App](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm?hl=en) if you use Chrome.  Postman will let you run REST commands in a nice GUI rather than using command line.

Confirm that your ElasticSearch instance is running by the following command in your command line / Postman App.

```curl -XPOST 'http://localhost:9200/?pretty'```

You should see a nice prettified json response if everything is working okay.

```
{
    "status": 200,
    "name": "Mystique",
    "cluster_name": "elasticsearch_mitch",
    "version": {
        "..."
    },
    "tagline": "You Know, for Search"
}
```

## Setting up Laravel

I have a fresh Laravel App up and running with a MySQL database. If you are unfamiliar see the [Laravel docs on installing](http://laravel.com/docs/4.2/installation).

## Packages

We'll be using 2 packages in this tutorial, Elasticquent and Faker.  You can ignore faker if you plan on importing your own data. For the sake of the tutorial I'll include it.

Open composer.json and add the following to the ```require``` object:

```
"fairholm/elasticquent": "1.0.*",
"fzaninotto/Faker": "1.4.*"
```

Run ```composer update --prefer-dist``` and we'll create our database table.

## Generating our database table

We're going to set up a "posts" table with 3 fields: title, content and tags.

```php artisan migrate:make create_posts_table```

In your migration file (located in ```app/db/migrations/<DATETIME>_create_posts_table.php```) use the following code:

```php
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

Do a migration and then we'll move on to generating some dummy data.

```php artisan migrate```


## Dummy data

We're going to set up a bunch of test data in a seeder file.  This will let us test that the search works without the hassle of inserting data manually.

Our initial post model should look like this ```app/model/Post.php```

```php
<?php

class Post extends Eloquent {
  public $fillable = ['title', 'content', 'tags'];
}
```

Create ```app/database/seeds/PostsTableSeeder.php``` and add the following code

```php
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

After running ```php artisan db:seed --class="PostsTableSeeder"``` we should now have plenty of test data to work with!

## Setting up Elasticquent

Let's edit our model in ```app/models/Post.php``` and add the following:

```php
<?php
use Elasticquent\ElasticquentTrait;

class Post extends \Eloquent {
  use ElasticquentTrait;

  public $fillable = ['title', 'content', 'tags'];

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

On line 2 we create the Elasticquent Trait shortcut and on line 5 we include it in our class.

Line 9 we add our mapping configuration for ElasticSearch.  You can read more about mappings [here](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping.htmlhttp://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping.html).

Each mapping has a type and an analyzer. Type's can be various data types including strings, numbers and dates.  For now we will stick to the string type but be aware that different types allow you to take advantage of different things.  You can learn more about the types that ElasticSearch supports [here](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-types.html)

The analyzer determines how ElasticSearch stores your data for searching. I've chosen ```standard``` for title and content and ```stop``` for tags.  The standard analyzer will remove HTML and grammar and index each word separately.  The stop analyzer can be set to choose which characters split the words for indexing.

As an example take this sentence:

> I love laravel, ElasticSearch and Laravel work well together.

With a standard analyzer ElasticSearch will create a list like this:

* i
* love
* laravel
* elasticsearch,
* and
* laravel
* work
* well
* together

With our settings the stop analyzer will group them like this:

* I love laravel
* ElasticSearch and Laravel work well together.

This can be advantagous if you want to prioritise certain phrases.

Now we've configured how we want our search to operate it's time to index our database!

Let's use Laravel's REPL to generate our ElasticSearch data. Go to your command line and type 

```
php artisan tinker
```

Type the following commands

```php
Post::createIndex($shards = null, $replicas = null);

Post::putMapping($ignoreConflicts = true);

Post::addAllToIndex();
```

The first command sets up our index.  An index is sort of like a database table in the ElasticSearch world.

```putMapping()``` takes the mapping properties we set in the model so that ElasticSearch knows how to index all of our data.

```addAllToIndex()``` takes all the data from the database and puts it into ElasticSearch

## Useful ElasticSearch API methods

Elasticquent sets up our index as "my\_custom\_index\_name" by default.  We can view our mappings by using the following curl request

```curl localhost:9200/my_custom_index_name/_mapping?pretty```

```
{
  "my_custom_index_name" : {
    "mappings" : {
      "posts" : {
        "properties" : {
          "content" : {
            "type" : "string",
            "analyzer" : "standard"
          },
          "created_at" : {
            "type" : "string"
          },
          "id" : {
            "type" : "long"
          },
          "tags" : {
            "type" : "string",
            "analyzer" : "stop"
          },
          "title" : {
            "type" : "string",
            "analyzer" : "standard"
          },
          "updated_at" : {
            "type" : "string"
          }
        }
      }
    }
  }
}
```

In ElasticSearch a table is called a type.  We can view all of the documents in a specific type with this query:

```
curl 'localhost:9200/my_custom_index_name/posts/_search?pretty'
```

We can do a basic do a basic search by altering the above command slightly

```
curl 'localhost:9200/my_custom_index_name/posts/_search?q=title:searchterm&pretty'
```

And we can view a specific document with this

```
curl 'localhost:9200/my_custom_index_name/posts/1?pretty'
```

For more info on the ElasticSearch API check out the [documentation](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/docs.html)

## Creating the front end

Add a route to ```app/routes.php```

```php
<?php
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

Make a template in ```app/views/home.blade.php```

```html
<html>
<body>
{{ Form::open(['method' => 'get', 'route' => 'search']) }}

  {{ Form::input('search', 'query', Input::get('query', ''))}}
  {{ Form::submit('Filter results') }}

{{ Form:: close() }}

@foreach($posts as $post)
 <div>
  <h2>{{{ $post->title }}}</h2>
  <div>{{{ $post->content }}}</div>
  <div><small>{{{ $post->tags }}}</small></div>
 </div>
@endforeach
</body>
</html>
```

In the above snippet we create a form that allows us to type in a search term. Below the form we iterate either through all of the posts or all of the search results depending on whether the user has entered a search term.

Here's how it looks currently.

![ElasticSearch Results](media/elastic-search-results.png)

We could stop now and the search would work fairly well. But where is the fun in that? Let's tinker and see how we can improve our search results.

## Fine-tuning your search

Elasticquent has another method called ```searchByQuery()``` which will allow us to specify more details on how we want ElasticSearch to query our data. Here's an example (taken and modified from the Elasticquent docs)

```php
<?php
$posts = Post::searchByQuery(['match' => ['title' => Input::get('query', '')]]);
```

In the above example only the title is searched. How does this differ from the ```search()``` method behind the scenes? The ```search()``` query will match all parameters including our content and tags fields.

If we try searching our data now with text from the ```content``` field you will notice drastically different results.  We may even notice different results when you take data from the title fields, too.  This is because ElasticSearch generates a score from the data it searches. Any relevant text in the queried fields will improve that score.

Let's give our ```title``` priority so that searches that match our titles will appear above those that only appear in the content.

```php
<?php
$posts = Post::searchByQuery([
  'multi_match' => [
    'query' => Input::get('query', ''),
    'fields' => [ "title^5", "content"]
  ],
]);
```

The caret symbol (^) lets ElasticSearch know we want the title field to have added weight to it by the number that follows it.

That's all well and good, but now we want to search our tags because they have specific keywords and phrases we want to match in the search results.

```php
<?php
$posts = Post::searchByQuery([
  'match_phrase' => [
    'tags' => Input::get('query', '')
  ]
]);
```

To make use of both searches we need to do a compound query.  There are many types of compound query but the one we'll use is the ```bool``` query.

```php
<?php
$posts = Post::searchByQuery([
  "bool" => [
    'must' => [
      'multi_match' => [
        'query' => Input::get('query', ''),
        'fields' => [ "title^2", "content"]
      ],
    ],
    "should" => [
      'match' => [
        'tags' => [
          "query" => Input::get('query', ''),
          "type" => "phrase"
        ]
      ]
    ]
  ]
]);
```

In a ```bool``` query we can specify three parameters: ```must```, ```should``` and ```must_not```.  In ours we have specified we must get a match from the title or content field and that we can optionally also get a match from the tags field.

We can also completely filter out specific terms if they are irrelevent with a filter.  Here we're using the [not_filter](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-not-filter.html).  You can read more on filters [here](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filters.html)

```php
<?php
$posts = Post::searchByQuery([
  'filtered' => [
    'filter' => [
      'not' => [
        'terms' => ['title' => ['impedit', 'voluptatem']]
      ]
    ],
    'query' => [
      "bool" => [
        'must' => [
          'multi_match' => [
            'query' => Input::get('query', ''),
            'fields' => [ "title^2", "content"]
          ],
        ],
        "should" => [
          'match' => [
            'tags' => [
              "query" => Input::get('query', ''),
              "type" => "phrase"
            ]
          ]
        ]
      ]
    ],
  ],
]);

```

Between lines 2-7 we're specifying that when 'impedit' or 'voluptatem' are not in the title. 

If we had a ```published``` field in out database another useful filter would be to only search published posts.

```php
<?php
$pages = $this->page->searchByQuery([
  'filtered' => [
    'filter' => [
      'term' => ['published' => '1']
    ],
    'query' => [
      'multi_match' => [
        'query' => Input::get('query', ''),
        'fields' => [ "title^2", "content"]
      ],
    ],
  ],
]);
```

## Summary

That's it for our search.  We've looked at setting up Elasticquent with our model and looked several ways we can customise our search results. 

We can use queries to order our search results by score, we can create compound queries for more complex search results and filters for simple boolean queries.

Although Elasticquent is great for a basic search engine there's also the official [ElasticSearch client for PHP](https://github.com/elasticsearch/elasticsearch-php) for when you need something more advance such as fragment highlighting or autocomplete. 

I'm really enjoying what I've learned so far with ElasticSearch and I'm very glad that I decided to pick it up.  I also really recommend [ElasticSearch Server - Second Edition](http://www.amazon.co.uk/gp/product/B00JXLF7AK/ref=as_li_tl?ie=UTF8&camp=1634&creative=19450&creativeASIN=B00JXLF7AK&linkCode=as2&tag=fullstan-21&linkId=3UGJUFM7O7NQS4GJ) (Amazon referral link).  I'm about 40% of the way through and I've learned a lot already.

![](http://ir-uk.amazon-adsystem.com/e/ir?t=fullstan-21&l=as2&o=2&a=B00JXLF7AK)
