---
title: Realtime chat with Laravel, Ember JS and Pusher
date: 2015-03-29 17:44 UTC
tags: Laravel, Laravel 5, Ember JS, Pusher, Bootstrap 3
change_frequency: never
ogp:
  og:
    description: ""
    title: 'Realtime chat with Laravel, Ember JS and Pusher'
    url: 'read/realtime-chat-with-laravel-ember-js-and-pusher/'
---

I've been hearing a lot of noise about [Firebase](https://www.firebase.com/) recently. Lots of good noise.  When I first started making this article I wanted to make use of [Firehose](http://firehose.io/) which is an open source alternative to Firebase. 

Setting up the API with Laravel was a breeze.  The only stumbling block was with my Ubuntu Vagrant box which installed a version of Redis which was too old (Firehose requries 2.6+ where as Ubuntu's package manager only has 2.2).   This was a pretty simple to fix and if you _are_ interested in Firehose then you can find instructions for getting the latest Redis [here](http://codecuriosity.com/blog/2013/10/29/install-redis-on-ubuntu/).

Anyway I started building my Ember application and I hit a brick wall.  Firehose touts Ember support out of the box but I can see literally no documentation on how to get started with it.

I decided to switch to Pusher which I'm already familiar with.  Unfortunately Pusher isn't open source but it does have a reasonable free package.  This allowed me to continue the use of my Laravel application where as switching to Firebase would not.  Also, there is already a pretty amazing Firebase Ember tutorial [here](https://www.firebase.com/blog/2015-03-13-ember-cli-in-9-minutes.html) so it seems pointless to do the same thing.

This article will show you a very bare bones chat system with Laravel 5, Ember JS 1.10 and Pusher.

READMORE

## Laravel

Start off by making a new Laravel application

```
laravel new realtimechat
```

For this application you'll use 2 packages:  [laracasts/Laravel-5-Generators-Extended](https://github.com/laracasts/Laravel-5-Generators-Extended) and [vinkla/pusher](https://github.com/vinkla/pusher).

Install the two packages

```
composer require laracasts/generators --dev
composer require vinkla/pusher:~1.0
```

In ```app/Providers/AppServiceProvider.php``` add the generator service provider as suggested in the documentation.

```php
if ($this->app->environment() == 'local') {
  $this->app->register('Laracasts\Generators\GeneratorsServiceProvider');
}
```

In ```config/app.php``` Add the Pusher service provider.  Do not add the facade as at the time of writing there is an issue with it.

```php
'Vinkla\Pusher\PusherServiceProvider'
```

Create a new migration for a table called messages

```
php artisan make:migration:schema create_messages_table --schema="name:string, body:string"
```

The first field, ```name```, will be the user's name.  The second field, ```body```, will be the content of the message.  You might be tempted to rename ```body``` to ```content``` (as I was).  I recommend that you don't because Ember's controllers and templates set ```content``` to the current model which makes things unnecessaryly confusing.

If you haven't configured your database settings then now is the time.  I'm using Sqlite for this application which works perfectly well. Run the migration afterwards.

```
php artisan migrate
```

You will need to remove the global CSRF token protection provided by Laravel.  If your app has other non-API routes then I recommend wrapping them in ```Route::group``` with the CSRF middleware.  You can remove the global middleware in ```app/Http/Kernal.php``` by removing the ```App\Http\Middleware\VerifyCSRFToken``` line.

At this point make sure you have signed up at [Pusher](http://pusher.com) and create your first application. 

In your terminal publish the Pusher configuration file with this command

```
php artisan vendor:publish
```

Open up ```app/config/pusher.php``` and add your ```auth_key```, ```secret``` and ```app_id``` to the ```main``` array. These can be found on your Pusher application's dashboard.

In ```app/Http/routes.php``` add a new resource route.

```php
<?php
Route::resource('messages', 'MessagesController', ['only' => ['index', 'store', 'show']]);
```

You'll only be using ```index``` and ```store``` but it's worth defining ```show``` incase Ember tries to fetch a single row.

Now create the controller

```
php artisan make:controller MessagesController
```

Open up ```app/Http/Controllers/MessagesController.php``` and update the code as follows:

```php
<?php namespace App\Http\Controllers;

use App\Http\Requests;
use App\Http\Controllers\Controller;
use App\Message;

use Illuminate\Http\Request;
use Input;
use Response;
use GuzzleHttp\Client;
use Vinkla\Pusher\PusherManager;


class MessagesController extends Controller {

  protected $message;
  protected $pusher;

  public function __construct(Message $message, PusherManager $pusher)
  {
    $this->message = $message;
    $this->pusher = $pusher;
  }

	/**
	 * Display a listing of the resource.
	 *
	 * @return Response
	 */
	public function index()
	{
    $messages = $this->message->orderBy('id', 'desc')->take(5)->get();

    return Response::json(['messages' => $messages->toArray()]);
	}

	/**
	 * Store a newly created resource in storage.
	 *
	 * @return Response
	 */
	public function store()
	{
    $message = $this->message->create(Input::get('message'));

    $this->pusher->trigger('messages', 'new-message', ['message' => $message->toArray()]);

    return Response::json(['message' => $message->toArray()]);
	}

	/**
	 * Display the specified resource.
	 *
	 * @param  int  $id
	 * @return Response
	 */
	public function show($id)
	{
    $message = $this->message->findOrFail($id);

    return Response::json(['message' => $message->toArray()]);
	}
}
```

I have used dependancy injection for the ```Message``` model and for ```PusherManager``` which are set in the constructor.

You may also notice that the JSON responses wrap ```message``` for single objects and ```messages``` for collections.  This is how Ember will expect its data.  

If you're familiar with Ember then you might be already be considering converting the keys to camel case (created_at to createdAt etc). Don't worry about this for now.

You can also see this line of code

```
$this->pusher->trigger('messages', 'new-message', ['message' => $message->toArray()]);
``` 

When you create a new row in the database you want to tell Pusher so that each client can be notified.

The ```index``` method on line 30 takes the latest 5 messages.  This as a nice way to introduce newly connected users to the chat without bombarding them with thousands of messages.  Feel free to adjust this to your preference.

At this point it's a good idea to test that the API for creating messages works because it's the trickiest to debug.  

There are a few ways that you can do this.  I've been using [Paw](https://luckymarmot.com/paw) which is a really sweet REST client.  [Postman - REST client](https://chrome.google.com/webstore/detail/postman-rest-client/fdmmgilgnpjigdojojpjoooidkmcomcm?hl=en) is an incredible free alternative. 

If you're thinking, "stop throwing all of these stupid apps in my face. Give me the Curl command!" then here you go.

```
curl -X POST -d "message[name]=Mitch" -d "message[body]=this is a message" 'http://realtime.dev/messages'
```

## Ember

Here's a preview of the final application:

![Realtime Chat](http://i.imgur.com/03wDiJq.png)

Once the messages reach the input fields a scrollbar will appear. The scrollbar will automatically scroll to the bottom when a new message is received.

Go ahead and install Ember CLI if you haven't already

```
npm install -g ember-cli phantomjs
```

For reference I'm using the following package versions with [IO.js v1.2.0](https://iojs.org/en/index.html)

* Ember-CLI 0.2.1
* Ember 1.10
* Ember-CLI-HTMLBars 0.7.4
* Ember Data 1.0.0-beta.16
* jQuery 1.11.2

Make a new Ember application.  I recommend doing so outside of your Laravel directory.

```
ember new realtime
```

After it's set up install the following add ons

```
ember install:addon ember-cli-pusher
npm install --save-dev ember-cli-content-security-policy
```

In your configuration file located at ```config/environment.js``` add your pusher key to the ```APP``` property.

```js
PUSHER_OPTS: {
 key: '<KEYHERE>',
 connection: {},
 logAllEvents: false
}
```

Then above the ```return ENV;``` add these Content Security Policy settings - this is necessary for Pusher's data to be retrieved. You can remove the bootstrap stylesheet in ```style-src``` if you wish to include it locally or not at all.

```js
ENV['contentSecurityPolicy'] = {
    'default-src': "'none'",
    'script-src': "'self' http://stats.pusher.com/",
    'connect-src': "'self' ws://ws.pusherapp.com/", 
    'img-src': "'self'",
    'style-src': "'self' 'unsafe-inline' http://maxcdn.bootstrapcdn.com/",
    'media-src': "'self'",
  };
```

Make ```messages``` the root route in ```app/router.js```

```js
import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.resource('messages', {path: '/'}, function() {});
});

export default Router;
```

Run the following command to change the ```RestAdapter``` to one that will work with our API.

```
ember g adapter application
```

In ```app/adapters/application.js``` update the adapter name like so:

```js
import DS from 'ember-data';

export default DS.ActiveModelAdapter.extend({
});
```

```ActiveModel``` is a thin wrapper around the Ruby on Rails' ORM ```ActiveRecord```.  I'm using this adapter because the API expects data in the same format. This is why you don't need to worry about updating camel case properties to snake case: ```ActiveModelAdapter``` handles it all for you.

Create a ```message``` model which defines the message properties.

```
ember g model message
```

```js
// app/models/message.js
import DS from 'ember-data';

export default DS.Model.extend({
  name: DS.attr('string'),
  body: DS.attr('string'),
  createdAt: DS.attr('string'),
  updatedAt: DS.attr('string')
});
```

Now create the messages route which will use the message model

```
ember g route messages
```

```js
// app/routes/messages.js
import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.store.find('message');
  }
});
```

The messages controller is the most complex part of the application. Create it with the following command.

```
ember g controller messages
```

```js
// app/controllers/messages.js
import Ember from 'ember';
import { Bindings } from 'ember-pusher/bindings';

export default Ember.ArrayController.extend(Bindings, {
  sortProperties: ['createdAt'],
  sortAscending: true,
  logPusherEvents: true,
  PUSHER_SUBSCRIPTIONS: {
    messages: ['new-message']
  },
  isValid: function() {
    return (this.get('name') && this.get('body'));
  }.property('name', 'body'),
  actions: {
    newMessage: function(data) {
      var _this = this,
      chat = jQuery('#chat');

      Ember.run.later((function() {
        _this.store.push('message', _this.store.normalize('message', data.message));
        Ember.run.schedule( 'afterRender', function () {
          chat.animate({scrollTop: chat[0].scrollHeight });
        });
      }), 200);
    },
    send: function() {
      var _this = this;
      if(this.get('isValid')) {
        var message = this.store.createRecord('message', {
          name: this.name,
          body: this.body
        });
        message.save().then(function() {
          _this.set('body', '');
        });
      } else {
        alert('Please enter a name and a message.');
      }
    }
  }
});
```

There's a lot of interesting stuff going on here.

You're importing Ember-pusher on line 2 and on lines 8-10 we subscribe to the 'new-message' event from Pusher.  When you receive this event Ember will automatically call the action of the same name (but camel cased).

On lines 6 and 7 you're setting how the data will be sorted.  Chat systems generally show the latest messages at the bottom so that's why ```createdAt``` is sorted ascending. Do not sort by id because ```sortProperties``` only supports strings and therefore '10' comes before '2'. This will give the appearance of a completely random order.

This ```newMessage``` action pushes the new message onto the model.  It waits a short moment to prevent duplicate entries on the client of the original message with ```Ember.run.later```.

The scrollbar for the chat system needs to automatically scroll to the bottom so that new messages can be seen. To do this ```Ember.run.schedule``` is run with ```afterRender``` (after the new message has been added to the DOM) and then jQuery is used to animate the chat to the bottom of the screen.

The last action, ```send```, is called when the form in the template is submitted.  The ```isValid``` property checks that the ```name``` and ```body``` has been filled in before sending to the API. Then after the message is saved the ```body``` value is cleared so the user can start writing new messages in the input field.

For the user interface I've chosen to use Twitter Bootstrap 3.2.

Add the bootstrap stylesheet it into ```app/index.html```

```html
<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css">
```

and add the following styles into ```app/styles/app.css```

```css
.message {
  background-color: #f3f3f4;
  color: rgba(0, 0, 0, 0.5);
  border-color: rgba(0, 0, 0, 0.1);
  margin-top: 20px;
  margin-bottom: 0px;
  padding: 15px;
  border: 1px solid;
  border-radius: 4px;
}
.message:first-child {
  margin-top: 0px;
}

#chat {
  overflow: auto;
  height: 340px;
}

.form-chat {
  margin-top: 20px;
}
```

Update ```app/templates/application.hbs``` like so

```html
<div class="container">
  <div class="row">    
    <div class="col-xs-12">
      <h2 id="title">Ember Chat</h2>
    </div>
  </div>
  {{outlet}}
</div>
```

Then in ```app/templates/messages.hbs```

```html
  <div class="row">    
    <div class="col-xs-12">
      <div id="chat">
        {{#each message in arrangedContent}}
          {{message-row message=message}}
        {{/each}}
      </div>
    </div>
  </div>
  <form {{action "send" on="submit"}} class="form-chat">
    <div class="row">    
      <div class="col-xs-2">
        {{input placeholder="Name" classNames="form-control" value=name}}
      </div>
      <div class="col-xs-9">
        {{input placeholder="Message" classNames="form-control" value=body}}
      </div>
      <div class="col-xs-1 text-right">
        <button {{bind-attr class=":btn :btn-primary isValid::disabled"}}>Send</button>
      </div>
    </div>
  </form>
```

Here there is a form with an action ```send``` which is sent to the messages controller. The send button has 2 static classes and 1 dynamic one.  When the controller's ```isValid``` property is false then the ```disabled``` class will be added to the button - giving it the appearance of being unusable.

On lines 4-6 the messages are looped through and sent to a ```message-row``` component which we'll create next.

```
ember g component message-row
```

in ```app/components/message-row.js```

```js
import Ember from 'ember';

export default Ember.Component.extend({
  tagName: 'div',
  classNames: ['message'],
  message: null
});
```

And for the template in ```app/templates/components/message-row.hbs```

```html
[{{message.createdAt}}] {{message.name}}: {{message.body}}
```

Components are partials with no context.  You can adjust their settings in ```app/components/*.js``` and adjust the templates in ```app/templates/components/*.hbs```.

If you haven't already then fire up Ember! Note the proxy argument which allows you to use Ember with your Laravel API.

```
ember server --proxy http://realtime.dev
```

## Preview

Here's a short video of the system in action. There are two browser windows are used to show the new messages being loaded in realtime.

<iframe src="http://gfycat.com/ifr/RichTinyDegus" frameborder="0" scrolling="no" width="600" height="338" style="-webkit-backface-visibility: hidden;-webkit-transform: scale(1);" ></iframe>

## Conclusion

In this article I have shown you how to set up a simple Laravel 5 API that's compatible with Ember JS.  I used Pusher to send realtime notifications to clients and discussed some of the alternatives briefly.  I then set up the chat system in Ember which sends and receives messages in realtime.

In some ways I've found this project easy but in others I feel I have failed. I'm quite disapointed that I couldn't get Firehose to work with Ember and if I had more time I would have liked to have pursued it further.

This application was done in one weekend and in my opinion it is far from finished. It could definitely do with authentication and there are some kinks that need to be ironed out.

One kink in particular is when a client sends a message it's pushed to the top of the chat because the ```createdAt``` timestamp is not set.  This fixes itself when the Pusher event updates it but it's not ideal.

I believe this could easily be fixed by adding ```moment.js``` and inserting the current time when creating a new record. If you've created the application yourself then I definitely recommend doing this as the next step.
