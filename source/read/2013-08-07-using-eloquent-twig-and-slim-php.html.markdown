---
title: Using Eloquent, Twig and Slim PHP
date: 2013-08-07 00:00 UTC
tags: Eloquent, Slim, Twig, PHP, slim-twig-eloquent
change_frequency: never
ogp:
  og:
    description: 'Originally while I was writing this blog I intended to make a step by step guide to putting together three of my favourite PHP tools. After a few issues and finding out that Slim Views is now a thing I decided instead to put together a git repo so anyone can get started quickly.'
    title: "Using Eloquent, Twig and Slim PHP"
    url: 'read/using-eloquent-twig-and-slim-php'
---

*Note*: See the [update to this post](/read/using-eloquent-twig-and-slim-php-revisited) where I've made several changes

Originally while I was writing this blog I intended to make a step by
step guide to putting together three of my favourite PHP tools. After a
few issues and finding out that [Slim Views](https://github.com/codeguy/Slim-Views) is now a thing I decided
instead to put together a git repo so anyone can get started quickly. I
will use this blog post to quickly show how it works!

*Note that this tutorial doesn’t aim to teach you Slim, Twig or Eloquent
- It’s to show you how to use them together effectively.*

You can find the repo here: [https://github.com/acoustep/slim-twig-eloquent](https://github.com/acoustep/slim-twig-eloquent)

After following the Installation instructions you should be able to use each component as well as Eloquent validation.

READMORE

### Folder Structure

* app/
  * config/
  * models/
  * views/
  * routes.php
  * application.php
  * Validator.php
* public/ (or public_html/)
  * css/
  * js/
  * images/
  * .htaccess
  * index.php
* vendor/
* config.php
* index.php

As the ```public/index.php``` calls ```/index.php``` from the root of the application which then includes ```config.php```, ```app/application.php``` and ```app/routes.php```.

```app/application.php``` sets Slim, Twig and Eloquent up so that you can create all of your Slim routes in ```app/routes.php```.

### Example Usage

Assuming you've now run ```git clone https://github.com/acoustep/slim-twig-eloquent.git```, ```composer install```, renamed the ```config.php``` file and changed your database settings let's create a table.  I've opted to use MySQL - here's the query to make a ```posts``` table:

```sql
CREATE TABLE `posts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;
```

A simple table with an unique id integer, title string, content text, created_at datetime and updated_at timestamp.

Next for the routes.  Enter the following in ```app/routes.php```:


```php
<?php
/* new */
$app->get( '/posts/new', function () use ( $app, $data ) {
  $data['post'] = new Post;
  $app->render( 'posts_new.twig', $data );
})->name( 'posts_new' );

/* create */
$app->post( '/posts', function () use ( $app, $data ) {
  $post = new Post;
  $post->title = $_POST['title'];
  $post->content = $_POST['content'];
  if( $post->validate( array( 
    'title'   => $_POST['title'], 
    'content' => $_POST['content'] 
  )))
  {
    $post->save();
    $app->flash( 'notice', "you're post has been created" );
    $app->redirect( $app->urlFor( 'posts_index' ) );
  }
  else
  {
    $app->flash( 'error', 'your post was not valid' );
    $app->flash( 'errors', $post->errors() );
    $app->redirect( $app->urlFor( 'posts_new' ) );
  }
})->name( 'posts_create' );

/* view all */
$app->get( '/posts', function () use ( $app, $data ) {
  $data['posts'] = Post::all();
  $app->render( 'posts.twig', $data );
})->name( 'posts_index' );
```

Above there are three routes.  GET ```/posts``` to view all posts,  GET ```/posts/new``` to enter a new post and POST ```/posts``` to create the post.  On lines 9 and 31 you can see calls to a class ```Post``` which we will create shortly in our models directory.  On line 12 you can see that you can use ```$posts->validate()``` to verify entered input.

Here's the  model along with validation located in```app/models/Post.php```


```php
<?php
class Post extends Illuminate\Database\Eloquent\Model
{
    protected $table = 'posts';
    private $errors;

    private $rules = array(
      'title'   => 'required|between:4,16',
      'content'  => 'required|min:3'
    );
    private $messages = array(
      'required' => 'Your :attribute is required.',
      'min'      => 'Your :attribute must be at least :min characters long.',
      'max'      => 'Your :attribute must be a maximum of :max characters long.',
      'between'  => 'Your :attribute must be between :min - :max characters long.',
      'email'    => 'Your :attribute must be a valid email address'
    );


    public function validate($params)
    {
        $validator = Validator::make( $params, $this->rules, $this->messages );
        if( $validator->fails() )
        {
          $this->errors = $validator->errors()->all();
          return false;
        }
        return true;
    }    

    public function errors()
    {
      return $this->errors;
    }
}
```

*Validation is entirely optional - If you do not require validation just create the class and extend ```Illuminate\Database\Eloquent\Model```*

At this point we just need to create our views - but before that you should run ```composer update``` so that your new model can be automatically loaded.

All templates are kept in ```app/views```  

posts.twig

```html
{% extends 'layout.twig' %}

{% block content %}
  <ul>
  {% for post in posts %}
    <li>{{ post.title }}</li>
    {% else %}
    There are no posts here :(
  {% endfor %}
  </ul>
  <a href="{{ urlFor('posts_new') }}">Create Post</a>
{% endblock %}
```

posts_new.twig

```html
{% extends 'layout.twig' %}

{% block content %}
 <form action="{{ urlFor('posts_create') }}" method="post">
 {% if flash.error %}
  <p>{{ flash.error }}</p>
  {% if flash.errors %}
    <ul>
    {% for error in flash.errors %}
    <li>{{ error }}</li>
    {% endfor %}
    </ul>
  {% endif %}
 {% endif %}
  <input type="text" name="title" placeholder="Title">
  <br>
  <input type="text" name="content" placeholder="Content">
<br>
  <input type="submit" value="Create">
 </form>
{% endblock %}
```

layout.twig (Put your layout in here as usual)

```php
{% block content %}
{% endblock %}
```

As you can see, Slim functions are available with ```urlFor()``` being called on line 11 in ```posts.twig``` and line 4 in ```posts_new.twig```.  You can also use Slim's flash functionality to send messages to redirections.  At this point everything should work!

### Custom Configurations

Perhaps you don't want your templates to be in a view folder, you want to disable twig caching or change error reporting for different environments?

99% of the magic inside of ```app/application.php```.  This is where Slim is instantiated along with Twig and Eloquent. Make sure that you take a look so you can perfect your own set up!

### Resources

While putting this together I came across some links which helped me out a lot.  Here are as many as I can remember:

* [Slim and Laravel Eloquent ORM](http://www.slimframework.com/news/slim-and-laravel-eloquent-orm)
* [Fix Class 'Twig\_Extensions\_Slim' not found](https://github.com/codeguy/Slim-Extras/pull/58)
* [Mixing and Matching PHP Components with Composer](http://www.12devsofxmas.co.uk/post/2012-12-29-day-4-mixing-and-matching-php-components-with-composer)
* [Slim Views](https://github.com/codeguy/Slim-Views)
