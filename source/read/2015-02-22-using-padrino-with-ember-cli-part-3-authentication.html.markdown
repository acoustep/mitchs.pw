---
title: "Using Padrino with Ember CLI Part 3: Authentication"
date: 2015-02-22 11:53 UTC
tags: Ruby, Padrino, Ember, Ember-CLI, Javascript, Sequel, sqlite, RABL, MiniTest
change_frequency: never
ogp:
  og:
    description: 'Welcome to Part 3 of my Padrino and Ember series.  This article is for setting up Ember with our Padrino API...'
    title: 'Using Padrino with Ember CLI Part 2'
    url: 'read/using-padrino-with-ember-cli-part-3-authentication/'
---

While thinking about what to write for this weeks article it occured that I never touched on authentication with Ember and Padrino in my previous articles. So I think this is the perfect excuse to continue with the series! Follow along for creating a Padrino backend that works with Ember-simple-auth and the authentication library Ember-simple-auth-devise.

READMORE

If you haven't been following along you can view them here:

* [Part 1: Setting up the Padrino API](/read/using-padrino-with-ember-cli-part-1)
* [Part 2: Setting up Ember CLI to work with Padrino](/read/using-padrino-with-ember-cli-part-2)

[You can also view the full source for the application on Github](https://github.com/acoustep/padrino-ember-example)

## Setting up the API

Change in to your Padrino application within your preferred command line application.

Before we start our deep dive into authentication open up your Gemfile, add bcrypt and run ```bundle install```.

```ruby
gem 'bcrypt-ruby', '~> 3.1.5'
```

We'll start by generating the ```User``` model which will have 6 fields: ```id```, ```email```, ```password```, ```authentication_token```, ```created_at``` and ```updated_at```

```padrino g model User email:string password:string authentication_token:string created_at:datetime updated_at:datetime```

Now we can run the migration:

```rake sq:migrate:up```

We need to make some changes to the model. Open  ```models/user.rb``` and add the following code  

```ruby
require 'bcrypt'
require 'securerandom'

class User < Sequel::Model
  Sequel::Model.plugin :timestamps

  attr_reader :readable_token

  def before_create
    self.password = BCrypt::Password.create(self.password)
    generate_authentication_token
  end

  def self.sign_in credentials
    user = self.first(email: credentials.fetch("email", ""))
    return false unless user
    return false if BCrypt::Password.new(user.password) != credentials.fetch("password", "")
    user.generate_authentication_token
    user.save
    return user
  end

  def generate_authentication_token(user=false)
    self.authentication_token = SecureRandom.urlsafe_base64(nil,false)
    @readable_token = self.authentication_token
    self.authentication_token = BCrypt::Password.create(self.authentication_token)
    return
  end

end
```
Just like the ```Post``` model we need to include the timestamps plugin so that our ```created_at``` and ```updated_at``` fields update appropriately.

Second, we need to add a ```before_create``` hook which generates an authentication token and hashes our passwords for us.

Third, we have added a static method for signing in.  This will take one parameter which is a hash of email and password. It will return an instance of ```User``` if valid and ```false``` otherwise.

Lastly, we've added a ```generate_authentication_token``` which handles the token generation.  

Because we should never store the token directly in the database we have to hash it. That puts us in a predicament.  How do we read the token but also make sure it's hashed in the database? We could do a ```before_save``` hook which automatically hashes unhashed tokens but what if we want to access the token after a save? We would be forced to invalidate a user's session and things start to get messy.

My solution is to create an instance variable named ```readable_token``` which gets a copy of the token before it's hashed.  This property is not placed in the database but is accessible after a token is generated for the remainder of the session.

This means 3 things:

* The database always has the correct token because it's always saved straight after generation.
* We have access to the token after generation which let's us use the token for the remainder of the session.
* If a user sends a separate request we will not have access to the readable token. This encourages us to check authorisation requests against the database hash rather than trying to do a sneaky shortcut and comparing it to the readable token.

For token generation we're using ```SecureRandom.urlsafe_base64(nil, false)```.  According to [this StackOverflow thread](http://stackoverflow.com/questions/6021372/best-way-to-create-unique-token-in-rails) Rails has now deprecated this method in favour of base58. 

I've tried to get base58 working but failed miserably.  At the time of writing I believe base58 is in the Rails/ActiveSupport master branch where as Padrino uses ActiveSupport 4.2.  I may come back to this in the future.

Let's seed a couple of users into our database to test everything's working. By default the Padrino seed command looks for a db/seed.rb file and runs it. I prefer to keep separate files for each model. So in db/seeds.rb put the following

```ruby
Dir[__dir__ + '/seeds/**/*.rb'].each {|file| require file}
```

And then create ```db/seeds/user.rb```.  In this file we'll truncate the database and create two users.

```ruby
User.truncate

User.create({
  email: "admin@admin.co.uk",
  password: "testpassword",
})
User.create({
  email: "example@example.co.uk",
  password: "testpassword",
})
```

**Tip:** Other Sequel methods such as ```multi_insert``` will ignore the ```before_create``` hook which means we don't get a hashed password or authentication token.

When we run ```padrino rake seed``` we can see the data that's been inserted into the database including our hashed passwords and authentication tokens

It's time to move on to the controller ```app/controllers/users.rb```. 

```ruby
Api::App.controllers "api/v1/users" do
  
  post :sign_in do

    user = User.sign_in params.fetch("user", {})

    if user
      @status = 201
    else
      @message = "Invalid login credentials" unless user
      @status = 401
    end

    @user = user
    status @status
    render "users/sign_in"
  end

end
```

Ember will be sending a ```user``` object which contains ```email``` and ```password``` key values.

If the user exists we want the request to return a status of 201 for successful creation.  If the credentials are invalid we set a message which will be passed to our RABL template.

Let's place the RABL template in ```app/views/users/sign_in.rabl```

```ruby
object @user => false
attributes :readable_token => :authentication_token, :email => :email
node (:message) {|m| @message }
```

We want to use the user object but we don't want the default behaviour of wrapping "user" around our attributes so we set it to ```false```.

Also notice how we're mapping ```readable_token``` to ```authentication_token``` for Ember.

The ```node``` block let's us add another attribute not associated with the user.  This message will host our error message to show the user.

Here's a couple of screenshots of how we can interact with the API via Postman APP and the structure of the JSON returned.

### Success

![Success](http://i.imgur.com/toncsAo.png)

### Failed

![Failed](http://i.imgur.com/eEwOUD0.png)

## Testing

So far we've done a shameful amount of testing. Well no more! I think at least for authentication it's important we have a few tests in place for peace of mind.

When we first generated the project we included MiniTest which Padrino has kindly set up for us. 

When we run ```padrino rake test``` we get a couple of failures due to some helper tests. Go in to ```test/app/helpers``` and remove the two files ```posts_helper_test.rb``` and ```users_helper_tests.rb```.  Running ```padrino rake test```  now brings us back to green.

Here is our ```test/app/controllers/users_controller_test.rb```

```ruby
require 'json'
require File.expand_path(File.dirname(__FILE__) + '/../../test_config.rb')

describe "/users" do
  before do
    User.create({
      email: "admin@admin.co.uk",
      password: "testpassword",
    })
  end

  it "should authenticate valid credentials" do
    post "api/v1/users/sign_in", {"user" => {"email" => "admin@admin.co.uk", "password" => "testpassword"}}
    json_response = JSON.parse last_response.body
    assert_equal nil, json_response["message"]
    assert_equal "admin@admin.co.uk", json_response["email"]
    assert_includes json_response, "authentication_token"
    assert_equal 201, last_response.status
  end

  it "should authenticate valid credentials" do
    post "api/v1/users/sign_in", {"user" => {"email" => "admin@admin.co.uk", "password" => "wrongpassword"}}
    json_response = JSON.parse last_response.body
    refute_nil json_response["message"]
    refute_includes json_response, "email"
    assert_equal 401, last_response.status
  end
end
```

The before block creates a valid User for us to test. From there we have two tests: one for testing valid credentials and one for testing invalid credentials. We test that the correct status and appropriate values are returned.

The ```test/app/models/user_test.rb``` is a little longer but still rather simple

```ruby
require File.expand_path(File.dirname(__FILE__) + '/../test_config.rb')

describe "User Model" do
  before do
    @user = User.create({
      email: "admin@admin.co.uk",
      password: "testpassword",
    })
  end

  it 'can construct a new instance' do
    user = User.new
    refute_nil user
  end

  it 'generates an authentication_token when created' do
    refute_nil @user, "authentication_token"
    refute_nil @user, "readable_token"
  end

  it 'generates a new authentication_token when signed in' do
    params = { "email" => "admin@admin.co.uk", "password" => "testpassword"}
    user = User.sign_in params

    readable_token = user.readable_token
    authentication_token = user.authentication_token

    user = User.sign_in params

    refute_equal readable_token, user.readable_token
    refute_equal authentication_token, user.authentication_token
  end
  
  it 'returns false with invalid credentials' do
    params = { "email" => "admin@admin.co.uk", "password" => "badpassword"}
    user = User.sign_in params

    assert_equal false, user
  end

  it "returns false when credentials aren't set" do
    params = { }
    user = User.sign_in params

    assert_equal false, user
  end
end
```

With this set of tests we're mostly focusing on the behaviour of the authentication token.  

Noteably, on lines 21 to 32 we're checking that signing in a second time regenerates the authentication token.

If you're using the Github repo or you want to see green colours fly by then make sure you install [minitest-reports](https://github.com/kern/minitest-reporters).

At this point we have some basic tests in place and ```padrino rake test``` should return green.  Our journey with Padrino is complete but Ember is calling us...

## Ember

Change directory in to your Ember app and run the following commands.

```
ember install:addon ember-cli-simple-auth
ember install:addon ember-cli-simple-auth-devise
```

Ember simple auth requires an authenticator.  We could create a custom one but this article is already long enough and Devise does the job. We're already simulating a Rails CRUD app. Why not simulate a Rails authentication library, too? Besides, it's pretty flexible.

If we go in to ```config/environment.js``` we can customise our authentication library to work with our API.  Let's add some code just above the ```return ENV```:

```js
  ENV['simple-auth-devise'] = {
    serverTokenEndpoint: '/api/v1/users/sign_in',
    tokenAttributeName: 'authentication_token',
    identificationAttributeName: 'email',
  };
  ENV['simple-auth'] = {
    routeAfterAuthentication: 'posts.index',
    routeIfAlreadyAuthenticated: 'posts.index'
  };
```

* ```serverTokenEndpoint``` is our API end point for signing in.
* ```tokenAttributeName``` is the name of our authentication token.
*  ```identificationAttributeName``` is the field we're sending back with the token to identify the user. In this case we're using the email.
*  ```routeAfterAuthentication``` and ```routeIfAlreadyExists``` is where to redirect to when necessary. By default this is ```index``` but since we made the route of our app ```posts``` we have to change it.

Time to whip out some more ember-cli commands. This time we need to make a login controller and two routes.

```
ember g controller login
ember g route application
ember g route login
```

We'll make a login form with help from [this error message example](https://github.com/simplabs/ember-simple-auth/blob/master/examples/2-errors.html).

In ```app/controllers/login.js```

```js
import LoginControllerMixin from 'simple-auth/mixins/login-controller-mixin';
import Ember from 'ember';

export default Ember.Controller.extend(LoginControllerMixin, {
  authenticator: 'simple-auth-authenticator:devise',
  actions: {
    // display an error when authentication fails
    authenticate: function() {
      var _this = this;
      this._super().then(null, function(error) {
        _this.set('errorMessage', error.message);
      });
    }
  }
});
```

We add the ```LoginControllerMixin``` so that this controller will have the methods for authenticating.  We override the authenticate action so that we can set our custom error message in the template.

In ```app/routes/application.js``` we need to include the ```ApplicationRouteMixin```

```js
import ApplicationRouteMixin from 'simple-auth/mixins/application-route-mixin';
import Ember from 'ember';

export default Ember.Route.extend(ApplicationRouteMixin);
```

Now we need to change the ```setupController``` inside of ```app/routes/login.js``` to remove previous error messages. If we dont then when a user fails logging in, goes to another route and then returns to login they will see the previous error message. 

```js
import Ember from 'ember';

export default Ember.Route.extend({
  setupController: function(controller, model) {
    controller.set('errorMessage', null);
  }
});
```

It's time we made a navigation bar.  Make the partial ```app/templates/-navigation.hbs```

```html
<nav class="navbar navbar-default">
    <!-- Collect the nav links, forms, and other content for toggling -->
    <div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
      <ul class="nav navbar-nav">
          {{#link-to 'posts.index' tagName='li'}}
            {{#link-to 'posts.index'}}
              Posts
            {{/link-to}}
          {{/link-to}}
        {{#if session.isAuthenticated}}
          <li><a {{ action 'invalidateSession' }}>Logout</a></li>
        {{else}}
        {{#link-to 'login' tagName='li'}}
          {{#link-to 'login'}}
            Login
          {{/link-to}}
        {{/link-to}}
        {{/if}}
      </ul>
    </div><!-- /.navbar-collapse -->
</nav>
```

We have an if statement (```if session.isAuthenticated```) which let's us show different links depending on whether the user is logged in.

Notice the nested ```link-to``` tags. Ember adds an active class to the ```link-to``` helpers that match the current route but Bootstrap expects this on the list element rather than the anchor tag.  The nested ```link-to``` resolves this issue for us nicely.

Time for us to update our ```app/templates/application.hbs``` to include our new partial

```html
<div class="row">
  <div class="col-md-12">
    <h1>Welcome to Ember with Padrino</h1>
    {{partial "navigation"}}
  </div>
</div>
<div class="row">
  <div class="col-md-12">
    {{outlet}}
  </div>
</div>
```

![Screenshot of the new posts page](http://i.imgur.com/174LkRt.png)

Finally we can create our Login form. We're almost at the finish line guys!

```html
<h2>Login</h2>
<form {{action 'authenticate' on='submit'}} class="horizontal">
  {{#if errorMessage}}
  <div class="alert alert-danger">
    <p>
      <strong>Login failed:</strong> <code>{{errorMessage}}</code>
    </p>
  </div>
  {{/if}}
  <div class="form-group">
    <label for="identification" class="control-label">Email</label>
    {{input value=identification placeholder='Enter Email' classNames="form-control"}}
  </div>
  <div class="form-group">
  <label for="password" class="control-label">Password</label>
  {{input value=password placeholder='Enter Password' type='password' classNames="form-control"}}
  </div>
  <div class="form-group">
  <button type="submit" class="btn btn-primary">Login</button>
  </div>
</form>
```

![Screenshot of the login form](http://i.imgur.com/SfdqI4y.png)

Any method route that requires authentication can now include the ```AuthenticationRouteMixin``` mixin.

As an example.  Change the ```app/routes/posts/new.js``` to the following

```js
import Ember from 'ember';
import AuthenticatedRouteMixin from 'simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin, {
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

Now if we try to access the ```posts/new``` page without logging in we will be redirected to the login form.

## Is this production ready?

![No](http://i.imgur.com/BilqB9d.gif)

This article is merely proof of concept. There are a few reasons I would not recommend using this for anything you need to keep secure.

This post only covers authentication and not authorization. The authentication part of ember-simple-auth only covers the retrieval of a valid token from a successful log in. It will not check future requests for validity! That's where authorisation comes in which is not covered in this article.

I've also gone and rolled my own authentication in Padrino which is not ideal. I have not covered validation of users, making sure that email addresses are unique etc. Your best bet is to try to get Warden working with Padrino for a proper log in system.

If you're serious about securing your API, read [this StackOverflow post](http://stackoverflow.com/questions/18605294/is-devises-token-authenticatable-secure/18695244#18695244) which gives you a list of best practices for securing your tokens.

## Summary

This was a lot longer than I predicted. I guess I can only blame myself for trying to include both Padrino and Ember in one article!

I have covered so much in this article and while I can't speak for you, I can say it's been quite the learning experience for myself.  

We've covered the security precautions and ramifications of using Ember-simple-auth for authentication, how to implement a Padrino API compatible with the Ember-simple-auth-devise authentication library and giving users feedback on their incorrect logins.

We also touched on using MiniTest with Padrino, generating secure tokens in Ruby and restricting access to specific routes with Ember-simple-auth.


