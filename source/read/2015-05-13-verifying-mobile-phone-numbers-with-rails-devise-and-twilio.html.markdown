---
title: "Verifying mobile phone numbers with Rails, Devise and Twilio"
date: 2015-05-13 18:26 UTC
tags: Rails, Devise, Twilio, Rails 4.2
change_frequency: never
ogp:
  og:
    description: "Verifying mobile phone numbers with Rails, Devise and Twilio"
    title: "Verifying mobile phone numbers with Rails, Devise and Twilio"
    url: 'read/verifying-mobile-phone-numbers-with-rails-devise-and-twilio'
---

This article will cover setting up a new Rails (4.2) application with Devise and allow users to add their mobile phone number to their account.

We'll use the [phonelib](https://github.com/daddyz/phonelib) gem to validate numbers and then send a 6 digit code via [Twilio](https://www.twilio.com/) to the user's mobile to verify that it's theirs.

I'll be starting afresh with a new Rails application.

```
rails new verify
```

## Dependancies 

Add the following dependancies to your ```Gemfile```

```ruby
gem "devise", '~>3.4.1'
gem 'twilio-ruby', '~> 4.0.0'
gem 'phonelib'
gem 'dotenv-rails', :groups => [:development, :test] # optional
```

Run ```bundle``` to install the new gems.

Devise is the authentication system we'll be using.

Twilio-ruby will be used to send text messages. Make sure you sign up at [Twilio](https://www.twilio.com/) and make a note of your test credentials.  

Note that when you use test credentials you will not receive a text. You'll only receive an API response from Twilio.

[Phonelib](https://github.com/daddyz/phonelib) is a gem which validates phone numbers based on Google libphonenumber.

[Dotenv](https://github.com/bkeepers/dotenv) let's you set environment variables in development.  I use this to set Twilio test credentials but you can set them your own preferred way if you wish.

## Setting up Devise

Run devise:install to set it up.

```
rails generate devise:install
```

Make sure you have a home route in ```config/routes.rb``` as described in the post-installation command notes.

```ruby
root to: "home#index"
```

Add flash messages to your ```app/views/application.html.erb```.

*Source [StackOverflow](http://stackoverflow.com/a/17932167).*

```html
<%# Rails flash messages styled for Bootstrap 3.0 %>
<% flash.each do |name, msg| %>
  <% if msg.is_a?(String) %>
    <div class="alert alert-<%= name.to_s == 'notice' ? 'success' : 'danger' %>">
      <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
      <%= content_tag :div, msg, :id => "flash_#{name}" %>
    </div>
  <% end %>
<% end %>
```

Generate your Devise model.  I prefer to call mine ```User```.

```
rails generate devise User
```

Before you run the migration command add these three columns to ```db/migrate/20150509173432_devise_create_users.rb```

```ruby
t.string   :mobile_number
t.string   :verification_code
t.boolean  :is_verified
```

At this point you can run ```rake db:migrate```.

```mobile_number``` will hold each user's mobile number. ```verification_code``` will hold the generated code that you will send to their phone.  ```is_verified``` is a boolean which will become true after a successful verification.

At this point you need to make a user. You can either run the server and go to ```http://localhost:3000/users/sign_up``` or do it with ```rails console``` and this code: 

```ruby
User.create!({email: "example@email.com", password: "test12345"})
```

Log in at ```http://localhost:3000/users/sign_in``` with your credentials.

*Note that I haven't made a home controller or a home view. You will see an error when after logging in if you haven't either. It's not important for this article so long as you have successfully logged in.*

## Adding a mobile number

We need to add a new form to the user's edit profile page which allows a user to  add their mobile number.  To do this we need to publish the devise views so we can override them.

```
rails g devise:views
```

Add a new field to the form in ```app/views/devise/registrations/edit.html.erb```.

```html
  <div class="field">
    <%= f.label :mobile_number %><br />
    <%= f.text_field :mobile_number %>
  </div>
```

We will validate mobile numbers before we try to send texts to them.  Earlier we installed the gem phonelib which we'll set up now.

In  ```app/models/user.rb``` add the following validation.

```ruby
  validates_uniqueness_of :mobile_number
  validates :mobile_number, phone: { possible: false, allow_blank: true, types: [:mobile] }
```

```validates_uniqueness_of``` will make sure no two users have the same mobile number.

In the ```validates``` method we set up phonelib with ```possible: false``` which, if set to true, enables a faster validation which is less strict. ```allow_blank``` means a user can enter no number at all. and ```types``` sets the types of numbers that are valid.  Since we're sending texts I have set it to ```mobile```.  There are lots of types including ```voip``` and ```personal_number```.  You can see a full list in the gem's [read me](https://github.com/daddyz/phonelib).

If you need to restrict the country you can do so by creating ```config/initializers/phonelib.rb``` and adding this code

```ruby
Phonelib.default_country = "GB"
```

Since I am from the UK I will be using GB (Great Britain).

**Make sure you restart your rails server after adding this setting.**

At this point we need to add ```mobile_number``` to Devise's list of acceptable parameters.  The easiest way to do this is to override them in the registration controller.  Run the following command to generate all Devise controllers so that we can override them.

```
rails g devise:controllers acme
```

```acme``` is the module and directory to place the new controllers.  Call it what you prefer.  

You can remove all of the newly generated controllers except ```app/controllers/acme/registrations_controller.rb```.

Amend your devise route in ```config/routes.rb``` like so:

```ruby
  devise_for :users, :controllers => { :registrations => "acme/registrations"}
```

Now in ```app/controllers/acme/registrations_controller.rb``` add the following code.

```ruby
class Acme::RegistrationsController < Devise::RegistrationsController
  before_filter :configure_account_update_params, only: [:update]

  def configure_account_update_params
    devise_parameter_sanitizer.for(:account_update) << :mobile_number
  end
end
```

Note that this code should already exists and is commented out.  All we've done is change ```:attribute``` to ```:mobile_number```.

At this point a user can add a phone number and we can verify it's a valid number.  To go one step further we need to send the user a validation code for them to enter and verify that they are in possession of the phone.

## Sending a verification code to their mobile

First let's make a helper method in the ```User``` model which will tell us if the account needs to be verified

```ruby
# app/models/user.rb
# ...
  def needs_mobile_number_verifying?
    if is_verified
      return false
    end
    if mobile_number.empty?
      return false
    end
    return true
  end
# ...
```

If the user is already verified it will return false and if there is no mobile number to verify it will also return false. We'll be using this method shortly.

Create a new controller for handling mobile number verifications. I called mine ```VerificationsController```

```
rails g controller verifications
```

Add a route in your routes for the ```create``` method.

```ruby
# config/routes.rb
post 'verifications' => 'verifications#create'
```

If you're using ```dotenv``` then now is the time to create a ```.env``` file in the root of your project and add your test credentials.

```
TWILIO_SID=""
TWILIO_TOKEN=""
TWILIO_PHONE_NUMBER="+15005550006"
```

Bear in mind that ```TWILIO_PHONE_NUMBER``` is currently set to the test number which is for sending valid text messages.  Once you go live you will need to change it your own Twilio number.  You will need to get your own SID and token from your Twilio account.

Restart your rails server after updating your environment variables.

In the new controller add the following code

```ruby

# ...
def create
  current_user.verification_code =  1_000_000 + rand(10_000_000 - 1_000_000)
  current_user.save

  to = current_user.mobile_number
  if to[0] = "0"
    to.sub!("0", '+44')
  end

  @twilio_client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']
  @twilio_client.account.sms.messages.create(
    :from => ENV['TWILIO_PHONE_NUMBER'],
    :to => to,
    :body => "Your verification code is #{current_user.verification_code}."
  )
  redirect_to edit_user_registration, :flash => { :success => "A verification code has been sent to your mobile. Please fill it in below." }
  return
end
# ...
```

* On line 3 we create a random six digit verification code and assign it to the user.

* Lines 6-9 checks if the number starts with 0 and if it does then convert it to +44 (which is the UK dialing code). Alternatively you may wish to save this to the database instead of doing it for every text.

* On line 11 we create an instance of the Twilio class with our credentials.

* Lines 12-16 handles sending the message to Twilio.

* On line 17 we redirect back to the edit profile page.

We're going to add a "Verify mobile number" button to the edit page but there's no point in showing it if the user already has no mobile number or is already verified. This is where the ```needs_mobile_number_verifying?``` method from earlier comes in to play.  We'll add a helper method to store the logic for showing the form.

```
rails g helper acme/registrations
```

```ruby
# app/helpers/acme/registrations_helper.rb
module Registrations::RegistrationsHelper
  def mobile_verification_button
    return '' unless current_user.needs_mobile_number_verifying?
    html = <<-HTML
      <h3>Verify Mobile Number</h3>
      #{form_tag(verifications_path, method: "post")}
      #{button_tag('Send verification code', type: "submit")}
      </form>
    HTML
    html.html_safe
  end
end
```

On line 4 we return an empty string unless the user needs to be verified. On lines 5-11 we have a heredoc which contains the new form.   Note that we could use plain HTML here but the ```form_tag``` allows us to use a path and it also adds the CSRF token for us. Lastly, we return ```html.html_safe``` which will be the output when we use it in our view.

Now in ```app/views/devise/registrations/edit.html.erb``` add the following code after the main form.

```ruby
# ...
<%= mobile_verification_button %>
<h3>Cancel my account</h3>
# ...
```

Now this form will only show when ```is_verified``` is ```false``` and ```mobile_number``` is not empty.

At this point you should enter a mobile number and click the "Send verification code" button. 

With test credentials you won't receive a text but if you spin up ```rails console``` and type ```User.first``` you should see a 6 digit number in ```verification_code``` field.  This code will change each time you click the button.

## Entering the code for verification

Add a new route and controller method to handle verification

```ruby
# config/routes.rb
put 'verifications' => 'verifications#verify'
```

```ruby
# app/controllers/verifications_controller.rb
def verify
      if current_user.verification_code == params[:verification_code]
      current_user.is_verified = true
      current_user.verification_code = ''
      current_user.save
      redirect_to edit_user_registration_path, :flash => { :success => "Thank you for verifying your mobile number." }
      return
    else
      redirect_to edit_user_registration_path, :flash => { :errors => "Invalid verification code." }
      return
    end
end
```

Let's make another helper method which will work the same way as the previous one.

This form will display when the `verification_code` field isn't empty so the user can enter their code.

```ruby
# app/helpers/acme/registrations_helper.rb
  def verify_mobile_number_form
    return '' if current_user.verification_code.empty?
    p current_user.verification_code.empty?
    html = <<-HTML
      <h3>Enter Verification Code</h3>
      #{form_tag(verifications_path, method: "patch")}
      #{text_field_tag('verification_code')}
      #{button_tag('Submit', type: "submit")}
      </form>
    HTML
    html.html_safe
  end
```

Finally, add the helper to ```app/views/devise/registrations/edit.html.erb```. 

```html
<%= verify_mobile_number_form %>
```

You can check it's working by generating the verification code and using ```rails console``` ```User.first``` to retrieve and enter the correct code.

Once you're happy that it works we should let the user know if their mobile is verified in their profile

```html
  <div class="field">
    <%= f.label :mobile_number %><br />
    <%= f.text_field :mobile_number %> 
    <% if resource.is_verified %>
      You're mobile number is verified.
    <% end%>
  </div>
```

It's also a good idea to stop the code from showing in the log files.

```ruby
# app/models/user.rb
filter_parameter_logging :verification_code
```

## Final notes

You have a basis for the system here but it can be improved. 

If a user enters a new mobile number ```is_verified``` should be changed to ```false```.

If ```rand``` isn't secure enough for your verification code generator then take a look at [The Ruby One Time Password Library](https://github.com/mdp/rotp).

The current set up is only ideal for users that have one mobile number. What happens if they want to enter more than one?

Lastly, as with emails, sending text messages can be slow. Not waiting-for-a-video-to-load-on-dial-up slow but enough for me to recommend setting up ActiveJob.  I've been having some good success with Resque for this task.

Here's a quick snippet of the code I've used on a recent project.

```ruby
#  controller 
SendVerificationCodeJob.perform_later(user)

# app/jobs/send_verification_code_job.rb
class SendVerificationCodeJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    # generate verification code

    user.verification_code =  100_000 + rand(1_000_000 - 100_000)

    user.save
    to = user.mobile_number
    if to[0] = "0"
      to.sub!("0", '+44')
    end

    # twilio send 
    @twilio_client = Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_TOKEN']

    @twilio_client.account.sms.messages.create(
      :from => ENV['TWILIO_PHONE_NUMBER'],
      :to => to,
      :body => "Your verification code is #{user.verification_code}."
    )
  end
end
```
