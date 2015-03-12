---
title: "Using Padrino with Ember CLI Part 4: Authorisation"
date: 2015-03-03 19:46 UTC
tags: Ruby, Padrino, Ember, Ember-CLI, Javascript, Sequel, sqlite, RABL
change_frequency: never
ogp:
  og:
    description: 'Welcome to Part 3 of my Padrino and Ember series.  This article is for setting up Ember with our Padrino API...'
    title: 'Using Padrino with Ember CLI Part 4: Authorisation'
    url: 'read/using-padrino-with-ember-cli-part-4-authorisation/'
---

In the last article I went through how to implement authorisation with Ember-simple-auth and Padrino. The next logical step is to implement authorisation with the same toolset.

READMORE

If you haven't seen the rest of the series you can view them here:

* [Part 1: Setting up the Padrino API](/read/using-padrino-with-ember-cli-part-1)
* [Part 2: Setting up Ember CLI to work with Padrino](/read/using-padrino-with-ember-cli-part-2)
* [Part 3: Authentication](/read/using-padrino-with-ember-cli-part-3-authentication)
* [Part 5: Realtime](/read/using-padrino-with-ember-cli-part-5-realtime)

[You can also view the full source for the application on Github](https://github.com/acoustep/padrino-ember-example)

## Ember

On the Ember side of things it couldn't be easier to implement.

All we need to do is open up our configuration (```app/config/environment.js```) and add the ```authorizer``` property to our ```simple-auth``` environment variable.

```js
  ENV['simple-auth'] = {
    routeAfterAuthentication: 'posts.index',
    routeIfAlreadyAuthenticated: 'posts.index',
    authorizer: 'simple-auth-authorizer:devise'
  };
```

Let's take a look at the header request for the posts API when we aren't logged in

[![Not logged in](http://i.imgur.com/43c5W5O.png)](http://i.imgur.com/43c5W5O.png)

Now let's compare that to when we are logged in

[![Logged in](http://i.imgur.com/eSBET4k.png)](http://i.imgur.com/eSBET4k.png)

As you can see: authorisation is sent with our email and our token.  This will occur on every request so it's up to you to decide with Padrino which API requests need guarding or filtering.

Before we move on to the Padrino section of this article I think it's important for you to be aware of one important feature of Ember-data.

By convention Ember will use something similar to this line of code to fetch a specific post.

```js
store.find('post', 15)
```

This request queries the server if the post hasn't already been loaded. If the user has viewed the list of posts then it will have been.  Therefore there will be no authorisation checks. With this in mind make sure that you filter out data in the API rather than in Ember.

## Padrino

I want to mention a sweet tip when working with APIs in Ruby.

```ruby
return JSON.pretty_generate(request.env)
```

If you can't find something that you think should be in the request there is no nicer way of formatting your request. There's also the [pretty print](http://ruby-doc.org/stdlib-2.1.1/libdoc/pp/rdoc/PP.html) library but that will only give you output in your command line.

Ember-simple-auth-devise sends the following to our API when we're logged in

```
"Token authentication_token="gDXbsrbDq2H9CKKG42Ts0A", email="admin@admin.co.uk""
```

It isn't the easiest string to parse but taking a little inspiration from Rail's [HttpAuthentication module](https://github.com/rails/rails/blob/25b14b4d3238d5474c60826ee1b359537af987ef/actionpack/lib/action_controller/metal/http_authentication.rb#L406) I came out the other end with this as my ```models/user.rb``` file.

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

  def self.authenticate(environment, parser=AuthorizationStringParser)
    credentials = parser.new(environment).parsed_string
    return false if credentials.nil?
    user = self.where(email: credentials.fetch("email", "")).first
    return false unless user
    return BCrypt::Password.new(user[:authentication_token]) == credentials.fetch("authentication_token", "")
  end
end

class AuthorizationStringParser
  attr_accessor :parsed_string, :environment
  def initialize(environment)
    @environment = environment
  end

  def parsed_string
    parsed_string ||= parse_string
  end

  protected

  def parse_string
    raw_param_string = environment.fetch("HTTP_AUTHORIZATION", "")
    raw_param_string.gsub(/Token\s|"|,/, "").split(' ').map { |key_value| key_value.split(%r/=(.+)?/) }.to_h
  end
end
```

On lines 32-38 we have the new ```self.authenticate``` method which takes the ```request.env``` (or any hash for that matter).  I chose pass the environment in as ```request``` is not available in the model and I didn't feel it was the controller's responsibility to handle parsing the token string.

It's also much nicer to just call ```User.authenticate request.env``` and let the model sort out the details. You could argue that it's not the model's responsibility to do this either.  If the application was larger I would consider creating a user repository to do it instead.

On line 32 we reference a new class (which is defined on lines 41-56) .  This ```AuthorizationStringParser``` is responsible for... parsing the authorisation string.

Between 34 and 36 we check if the credentials exist and if the user's email exists in our database. 

Finally on line 37 we use ```Bcrypt``` to check if the token that's sent is valid.

Now we should open up our posts controller at ```app/controllers/posts.rb``` and set the appropriate permissions for our API.

```ruby
require 'json'

Api::App.controllers :posts, map: "api/v1/posts", conditions: {:protect => true} do

  def self.protect(protected)
    condition do
      unless User.authenticate request.env
        halt 403, "No secrets for you!"
      end
    end if protected
  end

  get :index, map: "", protect: false do
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

On line 3 we've added a new parameter, ```conditions: {:protect => true}``` and on lines 5-11 there's a new ```self.protect``` method which will be called before every route in the controller.

This is where we take advantage of our new ```User.authenticate``` method and return a 403 error for invalid authorisation requests.

On line 13 and 27 we have disabled protection so that the posts can be accessed with out being logged in. All of the other routes that edit the data require authorisation.

### Tests

We best add some tests for our new authenticate method.  Open up ```test/models/user_test.rb``` and add the following.

```ruby

it "returns true when valid" do
  params = { "email" => "admin@admin.co.uk", "password" => "testpassword"}
  user = User.sign_in params

  authenticated = User.authenticate({"HTTP_AUTHORIZATION" => "Token authentication_token=\"#{user.readable_token}\", email=\"#{user.email}\""})
  assert_equal true, authenticated
end

it "returns false when invalid" do
  params = { "email" => "admin@admin.co.uk", "password" => "testpassword"}
  user = User.sign_in params

  User.sign_in params

  authenticated = User.authenticate({"HTTP_AUTHORIZATION" => "Token authentication_token=\"#{user.readable_token}\", email=\"#{user.email}\""})
  assert_equal false, authenticated
  end

it "returns false if no header is sent" do
  params = { "email" => "admin@admin.co.uk", "password" => "testpassword"}
  user = User.sign_in params

  User.sign_in params

  authenticated = User.authenticate({})
  assert_equal false, authenticated
end
```

## Tidying up Ember

At this point our authorisation is in place but it's hardly a good idea to leave all those buttons for adding, editing and deleting data lying around.

Let's change ```app/templates/posts/index.hbs``` to hide these buttons when the user's aren't logged in.

```html
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

We have already disabled viewing the new posts route in a previous article. We should do the same for the edit posts, too.  Open up ```app/routes/posts/edit.js``` and add the ```AuthenticatedRouteMixin```.

```js
import Ember from 'ember';
import AuthenticatedRouteMixin from 'simple-auth/mixins/authenticated-route-mixin';

export default Ember.Route.extend(AuthenticatedRouteMixin, {
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

Here are two previews of the system. One logged in and one logged out.
[![Logged in](http://i.imgur.com/Nl5LaD0.png)](http://i.imgur.com/Nl5LaD0.png)

[![Logged out](http://i.imgur.com/yKSuZyR.png)](http://i.imgur.com/yKSuZyR.png)

## Summary

That's it for authorisation with Ember and Padrino! We've covered setting up Ember to use the ember-simple-auth devise authoriser and updated our Padrino application which now reads the request headers to check for valid authentication details.

We've also restricted specific routes to users that are logged in and updated the Ember front-end to reflect these changes.
