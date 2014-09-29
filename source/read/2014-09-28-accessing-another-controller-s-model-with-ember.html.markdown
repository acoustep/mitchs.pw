---
title: Accessing another controller's model with Ember
date: 2014-09-28 08:12 UTC
tags: Ember, Emberjs, Ember 1.7, frontend, javascript, coffeescript
---

I've been learning Ember JS for a couple of months now and I absolutely love the structure of the system. There has been a few pain points on the way, I imagine this is to do with me being more of a backend developer and my Javascript skills aren't quite as sharp as my PHP/Ruby skills.

Yesterday I hit one of those pain points. Trying to access another controller's model.  I would like to have said "Accessing a model that isn't the default one for the current controller's", however, it seems to access another model you must do it through their controller. When I think of it this way it becomes slightly easier to wrap my head around.

Let's say for example you are creating a blog post and want to have a drop down select box for the category it belongs in.

First make sure your category has a model

```
App.Category = DS.Model.extend
  name: DS.attr 'string'
  posts: DS.hasMany 'post'
```

Second make sure your category has a route 

```
App.CategoriesRoute = Ember.Route.extend
  model: ()-> @store.find 'category'
```

Third, make sure your category has a controller. This one caught me out a bit, as Ember generally creates its own defaults if you don't set them up explicitly. However, when you use the ```needs``` property (which we will get to soon) you will come across this error: 

```
Error while processing route: posts.new <App.PostsNewController:ember605> needs [ controller:categories ] but it could not be found
```

So, just make sure the controller exists, even if there is nothing in it.

```
App.CategoriesController = Ember.ArrayController.extend()
```

Now your current controller can use the ```needs``` property to fetch the other controller's data.

```
App.PostsNewController = Ember.Controller.extend
  needs: 'categories'
```

```needs``` can be a string or an array depending on whether you need to access multiple controllers.

Next up, you need your current route to fetch that controller and it's data. Without this the data will only populate when you have already accessed the data via another page that retrieves it. This sounds kind of confusing right?

What I mean to say is, the data from the categories model won't be populated unless you tell it to.  So if you have been on the categories page you will have access to the categories data in your application.  This is because Ember has requested it from your API already.  If you went straight to the ```posts.new``` page, you need to tell Ember to download that data manually otherwise it won't check your API and it will presume that there are no categories. We can change this manually in the posts route's ```setupController``` method.

Also note that when you run ```setupController``` you over ride the original ```setupController``` which means you have to run ```@_super``` to make sure your controller and model are set.

```
App.PostsNewRoute = Ember.Route.extend(
  setupController: (controller, model) ->
    @_super controller, model
    @controllerFor('categories').set('content', @get('store').find('category'))
)
```

Now in your template you can access the category's data through ```controllers.categories```

For a dropdown menu you can use

```
view Ember.Select content=controllers.categories.content optionValuePath="content.id" optionLabelPath="content.name" prompt="Select Category" value=fields.category_id
```

If you just wish to iterate over the data you can use the following

```
each category in controllers.categories
  category.name
```

Hope that helps!
