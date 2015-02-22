---
title: Using Padrino with Ember CLI Part 2
date: 2015-02-15 09:17 UTC
tags: Ruby, Padrino, Ember, Ember-CLI, Javascript, Sequel, sqlite, RABL
change_frequency: never
ogp:
  og:
    description: 'Welcome to Part 2 of my Padrino and Ember series.  This article is for setting up Ember with our Padrino API...'
    title: 'Using Padrino with Ember CLI Part 2'
    url: 'read/using-padrino-with-ember-cli-part-2/'
---

Welcome to Part 2 of my Padrino and Ember series.  This article is for setting up Ember with our Padrino API.  If you missed part 1, go take a look [here](/read/using-padrino-with-ember-cli-part-1). You can view the full source on [Github](https://github.com/acoustep/padrino-ember-example).

I am using the following library versions for this tutorial:

* IO.js v1.2.0
* NPM 2.5.1
* watchman 3.0.0 (Installed with homebrew)
* Ember 1.8.1
* Ember Data 1.0.0-beta.14.1
* jQuery 1.11.2
* Handlebars 1.3.0

READMORE

Before starting make sure you’re in your ```Blog``` directory and not ```Blog/API```.  

To create our Ember application we'll use ```ember new app``` and then cd into it.

Run ```ember serve --proxy http://localhost:3000``` so that we can use our API. The proxy URL should match our Padrino API.  By default the port for Padrino is 3000.

## Bootstrap

I’m adding Bootstrap in ```app/index.html``` and changing the templates to use bootstrap as well. This is entirely optional. Feel free to use your own CSS / preferred CSS Framework.

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>App</title>
    <meta name="description" content="">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    {{content-for 'head'}}

    <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="assets/vendor.css">
    <link rel="stylesheet" href="assets/app.css">

    {{content-for 'head-footer'}}
  </head>
  <body>
    <div class="container">
      <div id="application">
      </div>
    </div>
    {{content-for 'body'}}

    <script src="assets/vendor.js"></script>
    <script src="assets/app.js"></script>

    {{content-for 'body-footer'}}
  </body>
</html>
```

In ```app/app.js``` we can add the ```rootElement``` parameter so that our Ember application gets loaded inside of the container.

```js
var App = Ember.Application.extend({
  modulePrefix: config.modulePrefix,
  podModulePrefix: config.podModulePrefix,
  Resolver: Resolver,
  rootElement: '#application'
});
```

Finally, in ```app/templates/application.hbs``` we’ll add some rows and columns to make use of Bootstrap’s responsive grid.

```html
<div class="row">
  <div class="col-md-12">
    <h2 id="title">Welcome to Ember with Padrino</h2>
  </div>
</div>
<div class="row">
  <div class="col-md-12">
    {{outlet}}
  </div>
</div>
```

### Routes

In ```app/router.js``` add the following routes:

```js
Router.map(function() {
  this.resource('posts', {path: '/'}, function() {
    this.resource('posts.new', {path: '/post/new'});
    this.resource('posts.show', {path: '/post/:post_id'});
    this.resource('posts.edit', {path: '/post/:post_id/edit'});
  });
});
```

This is what our Route should look like in Ember Inspector:

[![Ember Routes](http://i.imgur.com/gDaAlCR.png)](http://i.imgur.com/gDaAlCR.png)

### Adapter

We can set up the application adapter by running the following command

```ember g adapter application```

This will make a new file in ```app/adapters/application.js```.  Let’s change the code to work with our API:

```js
import DS from 'ember-data';

export default DS.ActiveModelAdapter.extend({
  namespace: 'api/v1'
});
```

On line 3 we change the adapter to be the Rails-style adapter.  As we’ve set our API to work the same way as Rails we can make use of its conventions.

On line 4 we prefix all API requests with ```api/v1``` which is how we’ve set it in our API.

### Routes and Resources

Let’s generate the Post resource, routes and templates. Ember CLI makes this super easy:

```
ember g resource posts title:string content:string createdAt:string updatedAt:string
ember g route posts/index
ember g route posts/new
ember g route posts/show
ember g route posts/edit
```

This sets us up with all the files we will need to edit.

Note how ```createdAt``` and ```updatedAt``` are camel case here but snake case in Padrino.  The ```ActiveModelAdapter``` will take care of this conversion so we don’t have to!

In ```app/routes/posts.js``` we should tell Ember where to find our posts like so:

```js
import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.store.find('post');
  }
});
```

## Index

Let’s update the posts index template in ```app/templates/posts/index.hbs``` to iterate over the posts:

```html
<h3>Latest Posts</h3>
<h3>Latest Posts</h3>
<table class="table table-striped">
  <tr>
    <th class=“col-md-3”>Title</th>
    <th class="col-md-3">Created at</th>
    <th class="col-md-3">Last modified</th>
    <th class="col-md-3">Actions</th>
  </tr>
{{#each post in model}}
<tr>
  <td>{{ post.title }}</td>
  <td>{{ post.createdAt }}</td>
  <td>{{ post.updatedAt }}</td>
  <td>
    {{#link-to 'posts.show' post classNames="btn btn-success"}}View{{/link-to}}
    {{#link-to 'posts.edit' post classNames="btn btn-info”}}Edit{{/link-to}}
    <button {{action 'delete' post}} class="btn btn-danger">Delete</button>
  </td>
</tr>
{{/each}}
</table>
{{#link-to 'posts.new' classNames="btn btn-primary"}}
  New Post
{{/link-to}}
```

Nothing too interesting is going on here. We are looping through our model in a Bootstrap-flavoured table.  Each post has 2 links, 1 to view the post and 1 to edit.  It also has an action to remove the post.  None of these do anything as of yet, so let’s get the rest of the application working.

## New

The posts new route file (```app/routes/posts/new.js```) will have three jobs:

```js
import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.store.createRecord('post');
  },
  deactivate: function() {
    var model = this.modelFor('posts/new');

    if(model.get('isNew')) {
      model.destroyRecord();
    }
  },
  actions: {
    save: function() {
      var _this = this;
      this.modelFor('posts/new').save().then(function() {
        _this.transitionTo('posts.index');
      });
    }
  }
});
```

The model method will create a new instance of post for us in the Ember application.

Deactivate will trigger if we switch out of the route without saving.  We use this because if we don’t save the the new post to the API (we click cancel) Ember will keep this “dirty” object hanging around in the application. ```destroyRecord``` will remove it for us.

Lastly we set the save action to create the post and go back to the posts.index route.

Modify two templates, ```app/templates/posts/new.hbs```

```html
<h3>New Post</h3>
{{ partial 'posts/form' }}
```

Our Form partial located in ```app/templates/posts/-form.hbs```

```html
<form {{action "save" on="submit"}}>
  <div class="form-group">
    <label for="title">Title</label>
    {{ input value=model.title class="form-control"}}
  </div>

  <div class="form-group">
    <label for="content">Content</label>
    {{ textarea value=model.content class="form-control"}}
  </div>

  <button type="submit" class="btn btn-primary">Save</button>
  {{#link-to 'posts.index'}}<button class="btn btn-default">Cancel</button>{{/link-to}}
</form>
```

This partial template will be used for our edit form as well.

Here’s the how the form looks now:

[![New Post](http://i.imgur.com/5ieTDRa.png)](http://i.imgur.com/5ieTDRa.png)

## Edit

```app/routes/posts/new.js``` will handle saving and rolling back if a user decides to cancel an edit:

```js
import Ember from 'ember';

export default Ember.Route.extend({
  deactivate: function() {
    var model = this.modelFor('posts/edit');
    model.rollback();
  },
  actions: {
    save: function() {
      var _this = this;
      this.modelFor('posts/edit').save().then(function() {
        _this.transitionTo('posts.index');
      });
    }
  }
});
```

And because we made our form a partial that is only tied to the existence of a model our ```app/templates/posts/edit.js``` is as simple as this

```html
<h3>Edit Post: {{model.title}}</h3>
{{ partial 'posts/form'}}
```

[![Edit Post](http://i.imgur.com/1U1nIMU.png)](http://i.imgur.com/1U1nIMU.png)

## Show

For when we want to view the post without editing.  Thanks to Ember having awesome conventions we only need to edit the template file ```app/templates/posts/show.hbs```

```html
<h3>{{model.title}}</h3>
<div>{{model.content}}</div>
{{#link-to 'posts.index' classNames="btn btn-default"}}Back{{/link-to}}
```

## Delete

Last but by no means least we need to place a delete action in our ```app/routes/posts/index.js```.  How else would we delete all the test posts we’ve made?

```js
import Ember from 'ember';

export default Ember.Route.extend({
  actions: {
    delete: function(post) {
      var _this = this;

      post.destroyRecord().then(function() {
        _this.transitionTo('posts.index');
      });
      
    }
  }
});
```

Here’s a preview of our posts index with a couple of posts added:

[![Posts](http://i.imgur.com/7xiLC8c.png)](http://i.imgur.com/7xiLC8c.png)

## What next?

If you're interested in setting up authentication you can check part 3 of this series, [Using Padrino with Ember: Authentication](/read/using-padrino-with-ember-cli-part-3-authentication).

There is a lot of room for growth. Things that are often needed in SPA’s include validation, flash messages and realtime data. 

They are all very doable with Padrino and Ember but are beyond the scope of this article.

For server-side validation take a look at the [Sequel validation documentation](http://sequel.jeremyevans.net/rdoc/files/doc/validations_rdoc.html).  Infact, the whole Sequel documentation is pretty awesome.

I recommend adding an error attribute to RABL objects which Ember can check for. If it exists it should stop transitions and loop through all of the errors in the template.

For flash messages I tend to create a mixin from the code in [this article](http://aaronvb.com/articles/ember-js-flash-messages.html) which works well.

For realtime data I’ve had success with [Pusher](https://pusher.com/) which has a nice free package. The [Pusher gem](https://github.com/pusher/pusher-gem) is really easy to integrate with Padrino.

## Summary

Well there you have it. Ember CLI with a Padrino backend. All the beauty of Ruby without the all of the unnecessary parts of Rails.

In these two posts we’ve covered a lot of the core functionality needed in any single page application. Creating, reading, updating and deleting data from our API and from Ember.

We’ve also taken a look at what we can use when we need to do more than just simple CRUD commands.

If you wish to see the full source for both of these articles you can view it on [Github](https://github.com/acoustep/padrino-ember-example).
