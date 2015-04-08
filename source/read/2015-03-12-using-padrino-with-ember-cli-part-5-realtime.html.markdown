---
title: 'Using Padrino with Ember CLI Part 5: Realtime'
date: 2015-03-12 20:14 UTC
tags: Ruby, Padrino, Ember, Ember-CLI, Javascript, Sequel, sqlite, Pusher
change_frequency: never
ogp:
  og:
    description: "In the final installment of my Padrino + Ember series I'd like to show you how to get some basic realtime functionality within your application"
    title: 'Using Padrino with Ember CLI Part 5: Realtime'
    url: 'read/using-padrino-with-ember-cli-part-5-realtime/'
---

_**Note**: This article was updated on 8th April 2015 thanks to [Phil](https://twitter.com/leggetter) from [Pusher](https://twitter.com/pusher) with a better solution for preventing duplicate data.  You can see the content of the original post [here](https://github.com/acoustep/mitchs.pw/blob/68f30561cd725758eccd103b3de98eb24f982bf9/source/read/2015-03-12-using-padrino-with-ember-cli-part-5-realtime.html.markdown)._

In the final installment of my Padrino + Ember series I'd like to show you how to get some basic realtime functionality within our application.  We'll be using [Pusher](http://pusher.com) to send and receive messages. They have a pretty reasonable free package which includes 100k messages per day, 20 max connections and SSL if you need it.

READMORE

If you haven't seen the rest of the series you can view them here:

* [Part 1: Setting up the Padrino API](/read/using-padrino-with-ember-cli-part-1)
* [Part 2: Setting up Ember CLI to work with Padrino](/read/using-padrino-with-ember-cli-part-2)
* [Part 3: Authentication](/read/using-padrino-with-ember-cli-part-3-authentication)
* [Part 4: Authorisation](/read/using-padrino-with-ember-cli-part-4-authorisation)

[You can also view the full source for the application on Github](https://github.com/acoustep/padrino-ember-example)

Make sure you've signed up at [pusher.com](http://pusher.com), make an application and make a note of your app_id, key and secret key.

## Padrino

Add the Pusher gem to your ```Gemfile``` and run ```bundle install```.

```ruby
gem 'pusher'
```


Inside your App class in ```app/app.rb``` add the following configuration block with your Pusher credentials. For production I do recommend storing these with [dotenv](https://github.com/bkeepers/dotenv) but I'll leave that for you to decide.

```ruby
  configure do
    Pusher.app_id = ''
    Pusher.key = ''
    Pusher.secret = ''
  end
```

Here are the changes to the posts controller

```ruby
# app/controllers/posts.rb
  # ...
  post :create, map: "" do
    parameters = post_params
    if parameters["post"].nil?
      return '{}'
    end
    @post = Post.create parameters["post"].except("socket_id")

    Pusher['posts'].trigger('new-post',  {post: @post.values}, parameters["post"]["socket_id"])

    render "posts/show"
  end

  # ...

  put :update, map: ":id" do
    @post = Post[params[:id]]

    if @post.nil?
      return '{}'
    end

    parameters = post_params
    @post.update parameters["post"].except("socket_id")
    render "posts/show"

  end
  # ...
```

We're going to be sending a new parameter called ```socket_id``` to our Padrino API from the Ember application.  ```socket_id``` is generated from Pusher in the Ember application and is unique for each user.

Notice on lines 8 and 25 we exclude ```socket_id``` as we don't have a ```socket_id``` field in our posts table to insert.

On line 10 we send the data to Pusher to tell applications that there is a new blog post. The key, ```posts```, is the channel. The first parameter ```new-post``` is the event, the second parameter is the data to send and the third parameter is client's socket id.

Sending the client's socket id means that Pusher will not send the event back to the user which created it. This will prevent duplicate data from showing in the poster's Ember application.

That's it for Padrino. It's really that simple!

Before moving onto the Ember part of the application make sure that Pusher is receiving the messages.  The easiest way to do this is to create a post in the Ember app and then go to the debug log in the Pusher dashboard.

![Pusher debugging](http://i.imgur.com/gc6N497.png)


## Ember

We need to install 2 addons for Ember. One of which is for Pusher and can be installed via command line

```ember install:addon ember-cli-pusher```

The other is to deal with CSP (Content Security Policy) when using Pusher.  

Without it we will get an error from our application like the following

```[Report Only] Refused to load the script 'http://stats.pusher.com/timeline/v2/jsonp/1?session=...' because it violates the following Content Security Policy directive: "script-src 'self' 'unsafe-eval' localhost:35729 0.0.0.0:35729".```

To fix this we use ```ember-cli-content-security-policy```.

Let's add it to our ```package.json```.  Currently we can't install it via command line  because there's a bug in the latest tagged release.  We need to get the latest version from Github.

 ```js
 "ember-cli-content-security-policy": "git://github.com/rwjblue/ember-cli-content-security-policy.git#master",
 ```

Run ```npm install``` afterwards.

Next we'll update ```config/environment.js```.  Make sure you put your Pusher key in the Pusher settings.

```js
    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
      PUSHER_OPTS: {
        key: '<YOURKEY>',
        connection: {},
        logAllEvents: false
      }
    },
```

We can add these CSP settings with the other ENV related content. Note that Bootstrap CDN is also included for fonts and stylesheets.

```js
  ENV['contentSecurityPolicy'] = {
    'default-src': "'none'",
    'font-src': "'self' http://maxcdn.bootstrapcdn.com/",
    'script-src': "'self' http://stats.pusher.com/",
    'connect-src': "'self' ws://ws.pusherapp.com/", 
    'img-src': "'self'",
    'style-src': "'self' 'unsafe-inline' http://maxcdn.bootstrapcdn.com/",
    'media-src': "'self'",
  };
```

Now that we have Pusher set up we need to generate the controller for the posts/index and modify it to receive the events.

```ember g controller posts/index```

In ```app/controllers/posts/index.js``` add the following:

```js
import Ember from 'ember';
import { Bindings } from 'ember-pusher/bindings';

export default Ember.ArrayController.extend(Bindings, {
  sortProperties: ['id'],
  sortAscending: false,
  logPusherEvents: true,
  PUSHER_SUBSCRIPTIONS: {
    posts: ['new-post']
  },
  actions: {
    newPost: function(message) {
      this.store.push('post', this.store.normalize('post', message.post));
    }
  }
});
```

We will switch the controller to an ArrayController so we can sort by ```id``` descending (so that newer posts appear at the top). Using the pusher library we subscribe to the posts channel and the ```new-post``` event. Note that when there is a ```new-post``` event an action is called with the camel-case version of the name. In this case ```new-post``` becomes ```newPost```.

Inside of the ```newPost``` action we use ```store.push``` which will find the post if it's already there or create it otherwise.  

Here is the newly updated ```posts/index.hbs```

```html
<h3>Latest Posts</h3>
<table class="table table-striped">
  <tr>
    <th class=“col-md-3”>Title</th>
    <th class="col-md-3">Created at</th>
    <th class="col-md-3">Last modified</th>
    <th class="col-md-3">Actions</th>
  </tr>
{{#each post in arrangedContent}}
<tr>
  <td>{{ post.title }}</td>
  <td>{{ post.createdAt }}</td>
  <td>{{ post.updatedAt }}</td>
  <td>
    {{#link-to 'posts.show' post classNames="btn btn-success"}}View{{/link-to}}
    {{#if session.isAuthenticated}}
      {{#link-to 'posts.edit' post classNames="btn btn-info"}}Edit{{/link-to}}
      <button {{action 'delete' post}} class="btn btn-danger">Delete</button>
    {{/if}}
  </td>
</tr>
{{/each}}
</table>
{{#if session.isAuthenticated}}
  {{#link-to 'posts.new' classNames="btn btn-primary"}}
    New Post
  {{/link-to}}
{{/if}}
```

Note that we're looping through ```arrangedContent``` now so that we that the data is ordered by ID descending.

At this point posts will get pushed to the on top until we hit an id of 10 which mysteriously goes to the bottom of the collection.  This is because Ember's sort works with strings not integers. The simplest solution is to switch ```id``` out for ```createdAt``` in your ```posts/index``` controller.

```js
sortProperties: ['createdAt'],
```

As mentioned in the Padrino part of the article we need to add a new parameter, ```socketId``` to the ```post``` model.

```js
// app/models/post.js
import DS from 'ember-data';

export default DS.Model.extend({
  title: DS.attr('string'),
  content: DS.attr('string'),
  createdAt: DS.attr('string'),
  updatedAt: DS.attr('string'),
  socketId: DS.attr('string')
});
```

```socketId``` will need to be sent when we create a new post. To do this we need to edit the ```save``` action in ```app/routes/posts/new.js```.

```js
  // ...
  actions: {
    save: function() {
      var _this = this;
      var post = this.modelFor('posts/new')
      
      post.set('socketId', this.pusher.get('socketId'));

      post.save().then(function() {
        _this.transitionTo('posts.index');
      });
    }
  }
  // ...

```

Notice how we get the model and assign the pusher ```socketId``` before saving it to the server.

### Notification messages

Maybe you don't want new data to be pushed on top all of the time.  This is a valid opinion, especially when considering the end user - who might be in the middle of reading a particularly long title. They might not appreciate the browser scrolling down all of the time and losing their place.

At this point I think something similar to how Twitter's website deals with new tweets would be ideal.  We'll show a little box with a message saying "1 New Post" and allow the user to click it to insert any new posts.

In ```app/controllers/posts/index.js``` update the code to the following

```js
import Ember from 'ember';
import { Bindings } from 'ember-pusher/bindings';

export default Ember.ArrayController.extend(Bindings, {
  sortProperties: ['createdAt'],
  sortAscending: false,
  logPusherEvents: true,
  PUSHER_SUBSCRIPTIONS: {
    posts: ['new-post']
  },
  newPosts: [],
  newPostCount: function() {
    return this.get('newPosts').length;
  }.property('newPosts.@each'),
  newPostsExist: function() {
    return !!this.get('newPostCount');
  }.property('newPosts.@each'),
  newPostMessage: function() {
    var wording = (this.get('newPostCount') !== 1) ? "New Posts" : "New Post";
    return this.get('newPostCount') + " " + wording;
  }.property('newPosts.@each'),
  actions: {
    newPost: function(message) {
      if(!this.store.hasRecordForId('post', message.post.id)) {
        this.get('newPosts').pushObject(message.post);
      }
    },
    refresh: function() {
      this.get('newPosts').forEach(function(post) {
        this.store.push('post', this.store.normalize('post', post));
      }, this);
      this.set('newPosts', []);
    }
  }
});
```

On line 11 we have a new property ```newPosts``` which by default is an empty array. Every time a new post is sent to Ember we will store it in here.

On line 12-14 we have a computed property called ```newPostCount``` which counts the number of posts we have stored in the ```newPosts``` array.

On lines 15-17 we have a computed property called ```newPostsExist``` which returns a boolean value for our template.  The double exclamation mark converts the ```newPosts``` length to false if it's 0 and true otherwise.

Lines 18-21 sets up the message we want to display to the user when a new post is available. This will be either "1 New Post" or "x New Posts".

In the ```newPost``` action on lines 23-27 instead of pushing the post into the store we put it in the ```newPosts``` array for later.

The refresh action on lines 28-33 will be a click event in our template which takes each post and pushes them into our store.

Each computed property has the following code: ```newPosts.@each```.  This allows them to watch for when the array has items added or removed.  This is ideal so that we can tell the user how many new posts there are.


Here is the new template in ```app/templates/posts/index.hbs```

```html
<h3>Latest Posts</h3>
{{#if newPostsExist}}
  <div class="alert alert-info click" {{action 'refresh'}}>
    {{ newPostMessage }}
  </div>
{{/if}}
<table class="table table-striped">
  <tr>
    <th class=“col-md-3”>Title</th>
    <th class="col-md-3">Created at</th>
    <th class="col-md-3">Last modified</th>
    <th class="col-md-3">Actions</th>
  </tr>
{{#each post in arrangedContent}}
<tr>
  <td>{{ post.title }}</td>
  <td>{{ post.createdAt }}</td>
  <td>{{ post.updatedAt }}</td>
  <td>
    {{#link-to 'posts.show' post classNames="btn btn-success"}}View{{/link-to}}
    {{#if session.isAuthenticated}}
      {{#link-to 'posts.edit' post classNames="btn btn-info"}}Edit{{/link-to}}
      <button {{action 'delete' post}} class="btn btn-danger">Delete</button>
    {{/if}}
  </td>
</tr>
{{/each}}
</table>
{{#if session.isAuthenticated}}
  {{#link-to 'posts.new' classNames="btn btn-primary"}}
    New Post
  {{/link-to}}
{{/if}}
```

We bind the click event ```refresh``` to the new alert so when a user clicks the message they receive the new posts and the alert gets removed.


Feel free to add some CSS or use anchor tags so that the cursor changes on hover and encourages the user to click!

```css
.click {
  cursor: pointer;
  cursor: hand;
}
```

![Final app](http://i.imgur.com/nQWToRN.png)

## Summary

In this post we've covered 2 ways of using Pusher to handle notifications. One where new posts get added directly to the store and another where we hold on to changes and let the user handle updates.  

I hope you have enjoyed this series and learned how awesome it is to use Padrino with Ember. Don't forget to check out the full source on [Github](https://github.com/acoustep/padrino-ember-example)!
