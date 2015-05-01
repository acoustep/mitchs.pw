---
title: Using Padrino with Ember CLI Part 1
date: 2015-02-11 20:59 UTC
tags: Ruby, Padrino, Ember, Ember-CLI, Javascript, Sequel, sqlite, RABL
change_frequency: never
ogp:
  og:
    description: 'After listening to the Ruby Rogues’ Padrino episode I was sold on the idea of using Padrino for smaller websites and simple API’s...'
    title: 'Using Padrino with Ember CLI Part 1'
    url: 'read/using-padrino-with-ember-cli-part-1/'
---
After listening to the Ruby Rogues’ Padrino episode I was sold on the idea of using Padrino for smaller websites and simple API’s.  I know [Grape](https://github.com/intridea/grape) is also a perfect contender for building an Ember APIs but:

* I am already familiar with Sinatra so the learning curve shouldn’t be as steep.

* I wanted to get to know Padrino.

* Funsies.
 
I’m going to show you how to quickly set up both together, build a restful API compatible with Ember’s ```ActiveModelAdapter``` and show you a few gotchas to help you on your way.  

READMORE

## Note

This article is aimed at people familiar with Ruby and have some understanding of the MVC pattern (ideally with Padrino or Rails). This article is not a guide for starting out with Padrino. If you have previous Ruby web framework experience you’ll most likely catch on quick.

On the Ember side of things you should be comfortable with Javascript, Ember and ideally Ember-CLI.

I will try to explain everything I do but this article is more about getting the two frameworks to work together.

You can view the full source for both of these articles on [Github](https://github.com/acoustep/padrino-ember-example).

## Getting Started

Make sure you have Padrino and Ember-CLI installed.  With Ruby and NPM this should be a matter of ```gem install pardrino```, ```npm install -g ember-cli``` and ```npm install -g bower```.
 
See Padrino’s [Installation Guide](http://www.padrinorb.com/guides/installation) and Ember CLI’s [Getting Started](http://www.ember-cli.com/#getting-started) for more details.
 
For reference I’m using the following library versions:

* IO.js 1.2.0 (Also tested with Node 0.10.36)
* NPM 2.5.1
* Ember-cli 0.1.15
* Ember 1.8.1
* Ember-data 1.0.0-beta.14.1
* Bower 1.3.12
* ruby-2.1.1
* Padrino 0.12.4

For a directory structure to this article we want 3 directories.
 

```
 - Blog
 |- API
 |- App
```

Make ```Blog``` main directory and change in to it.

```mkdir Blog && cd Blog```

## Setting up Padrino

One of the features of Padrino I love the most is the ability to swap different libraries to your preference. For instance, you have the choice to use your preferred ORM. If you know Rails then you will most likely be comfortable with ActiveRecord. 

I have recently been dabbling with Sequel and will be using it for this tutorial as I have become quite fond of it.

Run the following commands to set up Padrino

```
padrino g project API -d sequel -t minitest

cd ./API
bundle
```

Check the [Generators](http://www.padrinorb.com/guides/generators) documentation for more options.  You can specify css precompilers, Javascript libraries and mocking libraries as well. As they are not really relevant to this article I have left them off.

Open up your Gemfile in ```API/Gemfile``` and add the following gems:

```ruby
gem 'rabl'
gem 'oj'
gem 'rack-cors', :require => 'rack/cors'

# Optional
group :development do
  gem "better_errors"
end
```

[RABL](https://github.com/nesquena/rabl) stands for “Ruby API Builder language” and let’s us generate JSON for our API incredibly easily. I have to say, I found the documentation incredibly useful and I have found examples for every use case I’ve needed so far.

[Oj](https://github.com/ohler55/oj) is a RABL dependancy for “speed optimized JSON handling”.

[Rack/CORS](https://github.com/cyu/rack-cors) “provides support for Cross-Origin Resource Sharing (CORS) for Rack compatible web applications.”

[Better Errors](https://github.com/charliesome/better_errors) makes debugging so much easier. You can remove it for the tutorial but I do recommend using it in your own applications.

Run ```bundle``` to install the new dependancies.

For the sake of keeping the article short we will be creating the API in one Padrino application but it is possible to mount multiple Padrino apps within one another. 

We could have one app mounted to ```api/v1/``` and then, if we plan to upgrade our API, it’s as simple as mounting another app to ```api/v2/```. 

Take a look at the [Mounting Applications](http://www.padrinorb.com/guides/mounting-applications) documentation for more information on mounting apps. Also check [here](http://www.padrinorb.com/guides/generators#sub-app-generator) for generating the sub-applications.

## The Model

Keeping things simple, we’ll have one CRUD API for managing blog posts using using the default sqlite database.

We’ll make the model called ```Post``` that has 5 fields, ```id```, ```title```, ```content```, ```created_at``` and ```updated_at```

```
padrino g model Post title:string content:text created_at:datetime updated_at:datetime
```

This will create 3 files, your model, a migration file and a file for your model tests.

Open the migration file located in ```db/migrate/001_create_posts.rb``` and change the updated_at field to be nullable.

```ruby
Sequel.migration do
  up do
    create_table :posts do
      primary_key :id
      String :title
      Text :content
      DateTime :created_at
      DateTime :updated_at, null:true
    end
  end
 
  down do
    drop_table :posts
  end
end
```

When using Sequel you can migrate your database to the latest migration with this rake command:

```
rake sq:migrate:up
```

To make our timestamp columns behave like Ruby on Rails we need to add the Sequel timestamp plugin in our ```config/database.rb```.

```ruby
Sequel::Model.plugin(:timestamps)
```

In the ```models/post.rb``` add the following line:

```ruby
class Post < Sequel::Model
  Sequel::Model.plugin :timestamps
end
```

This line will sort out updating ```created_at``` and ```updated_at``` when necessary.

## The Controller

Run the following to generate the controller:

```
padrino g controller Posts get:index post:create get:show patch:update delete:destroy
```

This will create our controller in ```app/controllers/post.rb```.  We can see in the command we’ve deliberately left out new and edit methods from our CRUD API.  This is because Ember has no need to query them (at least it won’t for our simple application).

Running ```rake routes``` we’ll see how we can interact with the routes.

```
    URL                  REQUEST  PATH
    (:posts, :index)        GET    /posts
    (:posts, :create)      POST    /posts/create
    (:posts, :show)         GET    /posts/show
    (:posts, :update)      PATCH   /posts/update
    (:posts, :destroy)    DELETE   /posts/destroy
```

Let’s make it so api/v1 is prepended and for familiarity we’ll also modify our routes to mirror Rail’s conventions found [here](http://guides.rubyonrails.org/routing.html#crud-verbs-and-actions).

In ```app/controllers/post.rb``` change it to the following:

**Edit:** Big thanks to [Nathan Esquenazi](https://twitter.com/nesquena) for showing me a much cleaner way of doing it. For reference you can see my previous code [here](https://github.com/acoustep/padrino-ember-example/blob/1a0cadc73e4532cca781f2655106f4d878662575/API/app/controllers/posts.rb)

```ruby
Api::App.controllers :posts, map: "api/v1/posts" do
 
  get :index, map: "" do
 
  end
 
  post :create, map: "" do
 
  end
 
  get :show, map: ":id" do
 
  end
 
  patch :update, map: ":id" do
 
  end
 
  delete :destroy, map: ":id" do
 
  end
 
end
```

If you run ```rake routes``` now you should see the following:

```
    (:posts, :index)        GET    /api/v1/posts
    (:posts, :create)      POST    /api/v1/posts
    (:posts, :show)         GET    /api/v1/posts/:id
    (:posts, :update)      PATCH   /api/v1/posts/:id
    (:posts, :destroy)    DELETE   /api/v1/posts/:id
```

Much better. Now let’s fill in the details

```ruby
require 'json'
Api::App.controllers :posts, map: "api/v1/posts" do
  
  get :index, map: "" do
    @posts = Post.all
    render "posts/index"
  end

  post :create, map: "" do
    parameters = post_params
    if parameters["post"].nil?
      return '{}'
    end
    @post = Post.create parameters["post"]
    render "posts/show"
  end

  get :show, map: ":id" do
    @post = Post[params[:id]]
    render "posts/show"
  end

  put :update, map: ":id" do
    @post = Post[params[:id]]

    if @post.nil?
      return '{}'
    end

    parameters = post_params
    @post.update parameters["post"]
    render "posts/show"

  end

  delete :destroy, map: ":id" do
    @post = Post[params[:id]]
    @post.delete unless @post.nil?
  end

end

def post_params
  JSON.parse(request.body.read)
end

```

If you're familiar with Active Record you should see some familiar method names.  ```all```, ```create```, ```delete``` and ```update``` are self explanatory. You may be unfamiliar with how Sequel finds specific rows, though.

```Post[params[:id]]``` is the simplest way to retrieve a record by primary key.  ```params[:id]``` is just the URL id parameter. So it's more like calling ```Post[1]```.

Occasionally we return blank objects with 

```
return '{}'
```

This may seem unneeded but Ember expects a valid JSON response and if it doesn't get one it will throw a hissy fit.

### Views

Now we’ll get the JSON responses working. Sequel and RABL make this nice and easy.

Create these two files:

### app/views/index.rabl

```ruby
collection @posts, root: "posts", object_root: false
attributes :id, :title, :content, :created_at, :updated_at
```

### app/views/show.rabl

```ruby
object @post
attributes :id, :title, :content, :created_at, :updated_at
```

If you’ve never used RABL before this may look quite alien to you.

We use the ```collection``` method when working with multiple objects and the ```object``` method when specifying one object in particular.

The collection method has two parameters, ```root``` and ```object_root```. ```root``` specifies the parent key that wraps around the collection. We set ```object_root``` to false because by default RABL adds another key around each row.

Essentially we are changing this JSON:

```json
[{
  "post":
  {
    "id":1,
    "title":"test",
    "content":"test",
    "created_at":"2015-02-11 20:25:21 +0000",
    "updated_at":null
  }
}]
```

To this Ember-friendly JSON

```json
{
  "posts":
  [{
    "id”:1,
    ”title":"test",
    "content":"test",
    "created_at":"2015-02-11 20:25:21 +0000",
    "updated_at":null
  }]
}
```

Lastly, the ```attributes``` method lets us choose which data we want to show in our API.

### A word on CSRF Protection

#### The problem

With Rails and Ember-Rails it’s possible to set up CSRF protection by having an API end-point that provides the CSRF token. That token is then placed in a meta tag called ```csrf_token``` and then with Ember you set up an AJAX preFilter which sends the token in a header named ```X-CSRF-Token```.

All this is possible with Padrino’s ```csrf_token``` method, but due to the fact that your API and Ember-CLI are separate applications you will not have access to the session which verifies the token. 

#### The solution

You have 2 options. Disable CSRF entirely or, if your Padrino app is more than just an API, disable it for your API.

#### Disabling CSRF Entirely

Go to ```app/config/apps.rb``` and set the following

```ruby
set :protect_from_csrf, false
```

If your app is currently running make sure you restart it now with ```bundle exec padrino start```.

#### Disabling CSRF for your API

If you’re using Better Errors, go to ```app/config/apps.rb``` and set the following

```ruby
set :protect_from_csrf, except: %r{/__better_errors/\\w+/\\w+\\z} if Padrino.env == :development
```

If your app is currently running make sure you restart it now with ```bundle exec padrino start```.

In ```app/controllers/posts.rb``` we need to disable CSRF for any requests that aren’t ```get```.  We can do that by setting ```csrf_protection: false``` in the parameters.

```ruby
require 'json'
Api::App.controllers :posts, map: "api/v1/posts" do
  
  get :index, map: "" do
    @posts = Post.all
    render "posts/index"
  end

  post :create, map: "", csrf_protection: false do
    parameters = JSON.parse(request.body.read)
    if parameters["post"].nil?
      return '{}'
    end
    @post = Post.create parameters["post"]
    render "posts/show"
  end

  get :show, map: ":id" do
    @post = Post[params[:id]]
    render "posts/show"
  end

  put :update, map: ":id", csrf_protection: false do
    @post.update params
    render "posts/show"

  end

  delete :destroy, map: ":id", csrf_protection: false do
    @post = Post[params[:id]]
    @post.delete unless @post.nil?
  end

end
``` 

### CORS

We will be using Ember-CLI’s proxy option so we don’t have to worry about CORS. However for production you may want to include it.

In ```app/app.rb``` Add the following lines of code to your ```App``` class

```ruby
use Rack::Cors do
  allow do
    origins '*'
    resource '*', :headers => :any, :methods => [:get, :post, :options, :delete, :patch]
  end
end
```

If you look at the Rack/CORS documentation, you can specify URLs that are allowed to access your API by updating the origins method.

```ruby
origins 'localhost:4200' # Ember CLI App
```

Before moving on to Part 2 make sure your Padrino app is up and running.  Use ```bundle exec padrino start```.

### Summary

That’s it for part 1.  We’ve successfully made an API compatible with Ember’s ActiveModelAdapter. We’ve disabled CSRF where necessary and enabled CORS.

[Click here to view part 2 for implementing the Ember side of the project](/read/using-padrino-with-ember-cli-part-2).
