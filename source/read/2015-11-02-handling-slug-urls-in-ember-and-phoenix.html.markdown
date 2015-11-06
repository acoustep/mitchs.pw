---
title: Handling slug URLs in Ember and Phoenix
date: 2015-11-02 19:22 UTC
tags: Elixir, Phoenix, Ember JS,
change_frequency: never
ogp:
  og:
    description: "Handling slug URLs in Ember and Phoenix"
    title: "Handling slug URLs in Ember and Phoenix"
    url: 'read/handling-slug-urls-in-ember-and-phoenix'
---

I've recently started playing around with the PEEP stack (Postgres Elixir Ember Phoenix). One of the first things I wanted achieve is using slugs instead of ids in the URLs.

This article presumes you know how to set up a fresh Ember project and a fresh Phoenix application as I will be diving head first into the code. 

### Version info:
  
* Node 4.2.1
* Ember 1.13.8 / 2.0.2
* Elixir 1.0.5
* Phoenix 1.0.3
* PostgreSQL 9.4.5

There is no special configuration required for each to work together. Although, I recommend launching Ember with the proxy argument as shown below.

```bash
ember serve --proxy=http://localhost:4000
```

This means you don't have to worry about Content Security Policy between Ember and your API.

If you haven't already, check out Maxwell Holder's [Build a Blog with Phoenix and Ember.js](http://maxwellholder.com/blog/build-a-blog-with-phoenix-and-ember). This article really helped me get started with using Ember and Phoenix together.

I'll be demonstrating how to set up a product index which links through to product pages with a slug instead of an ID. This includes querying the slug on the API as well.

## Show me the code!

The code is available on Github: https://github.com/acoustep/ember-phoenix-slug-example

## Setting up Phoenix

First run ```mix ecto.create``` to make sure the database is set up correctly.

Phoenix provders a really useful generator for APIs. Run the following command to get the cruft of the work done for you.

```bash
mix phoenix.gen.json Product products name:string slug:string blurb:text preview:string featured:boolean
```

The above command generates the view, controller, migration and model files.

To make this accessible we need to add resource to the router.

```elixir
# web/router.ex
scope "/api", Api do 
  pipe_through :api
  resources "/products", ProductController, only: [:index, :show]
end
```
[Git Commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/059687bb6634e58752e870c6681876ed55b95db1)

We've added the API pipeline which we will be modifying shortly. For now, migrate the database in the terminal

```bash
mix ecto.migrate
```

As of now the API works, however, it needs a couple of tweeks to be compatible with Ember and to support slugs.

### Ember compatible API

Phoenix wraps JSON objects and collections with the "data" attribute but Ember (currently in 2.1 and below) uses the model's singular name for objects and plural name for collections.

```javascript
// Phoenix currently
{"data":[]}
```

```javascript
// What Ember wants
{"products":[]} // Collection
{"product":[]} // Single Objects
```

Phoenix makes this really easy to change.

In product view change the render map ```data``` keyword in both the ```index``` and ```show``` ```render``` methods.

```elixir
# web/views/product_view.ex
defmodule Api.ProductView do
  use Api.Web, :view

  def render("index.json", %{products: products}) do
    %{products: render_many(products, Api.ProductView, "product.json")}
  end

  def render("show.json", %{product: product}) do
    %{product: render_one(product, Api.ProductView, "product.json")}
  end

  def render("product.json", %{product: product}) do
    %{id: product.id,
      name: product.name,
      slug: product.slug,
      blurb: product.blurb,
      preview: product.preview,
      featured: product.featured,
  end
end
```
[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/ad372e8f6588e104ceb23e083ca3f8af6eb5b672)

### Just add slugs

To search for slugs instead of the id primary key, we need to replace the Repo.get with a query that uses Repo.one or Repo.one! in the product controller - using the exclamation marked versopn will throw an error if nothing is found. I recommend this route as you can configure Ember to redirect elsewhere in this situation.

```elixir
def show(conn, %{"id" => slug}) do
  query = from p in Product,
    where: p.slug == ^slug,
    select: p
  product = Repo.one!(query)
  render(conn, "show.json", product: product)
end
```
[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/d45d0fb8b9eff63784af5e11fd836e3b87858458)

On line 1 ```id``` has been altered to say ```slug```, this is just so we're clear that we're dealing with a slug. The map key is still ```id``` as the product resource route added previously is set up to pattern match for ```id```. To change it to ```slug``` requires adding a separate route.

Lines 2 to 4 is the query to find the slug in the database.

Line 5 uses Repo.one! to fetch the first match for the query or throw an error.

### CORS in production

Although using ember serve --proxy will solve this issue in development, it's worth adding this library now

(Corsica)[https://github.com/whatyouhide/corsica]

After following the installation instructions modify the API pipeline in the router:

```elixir
  pipeline :api do
    plug :accepts, ["json"]
    plug Corsica, origins: ["localhost:4200", "example.com"]
  end
```
[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/2fcfb08479549e451039b586cc64a2970289d3ce)

This will modify response headers to show which sources can load the API.

Make sure that you restart your Phoenix server after installing Corsica.

```bash
mix phoenix.server
```

Before you continue to the Ember section make sure you have some data in the database!

## Ember

Let's use Twitter Bootstrap to make the application look presentable.

```bash
ember install ember-bootstrap
```

Note that because I have named my app "App" I have had to rename my app.css to style.css

Modify the application template to use the bootstrap grid

```hbs
{{!-- app/templates/application.hbs --}}
<div class="container">
  <div class="row">
    <div class="col-xs-12">
      <h1 id="title">Ember Phoenix Slugs</h1>
    </div>
  </div>
  <div class="row">
    <div class="col-xs-12">
      {{outlet}}
    </div>
  </div>
</div>
```
[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/044ee7d5c3622e7f2dca25c7fe47e45116a0ad96)

Make sure you restart the Ember server after installing the addon.

```bash
ember serve --proxy=http://localhost:4000
```

Before we can hook up ember to the API, we need to generate the application adapter to add the 'api' namespace that we've set up in Phoenix.

```bash
ember g adapter application
```

Open up the newly created adapter file and add the namespace property.

```js
// app/adapters/application.js
import DS from 'ember-data';

export default DS.RESTAdapter.extend({
  namespace: 'api'
});
```

[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/2e85a9e40fd40ec1d27c9ab6d79ce564c21bf5bd)

Now we can set up the model we'll use to connect to the API

```bash
ember g model product
```

```js
// app/models/product.js
import DS from 'ember-data';

export default DS.Model.extend({
  name: DS.attr(),
  slug: DS.attr(),
  blurb: DS.attr(),
  preview: DS.attr(),
});
```

Generate the index route to connect to the product model.

```bash
ember g route index
```

```js
// app/routes/index.js
import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.store.findAll('product');
  }
});
```

Here is the template for the index. It loops through all the products and links to them in the image and headings.

```hbs
{{!-- app/templates/index.hbs --}} 
<h2>Products</h2>
<div class="row">
  {{#each model as |product|}}
    <div class="col-xs-3">
      {{#link-to 'product' product}}
        <img src={{product.preview}} class="product--image">
        <h3>{{product.name}}</h3>
      {{/link-to}}
      <p>{{product.blurb}}</p>
    </div>
  {{/each}}
</div>
```

[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/c3db53c239aed1f676db8c8c469d3e2535f8064a)

Note that if you're using Ember 2 or onwards you can remove the curly brackets around the image source value.

Next we need to generate the product route.

### Product page

As of now Ember will through an error due to using a product route which doesn't exist yet. Let's fix that.

```bash
ember g route product
```

```js
// app/routes/product.js
import Ember from 'ember';

export default Ember.Route.extend({
  model: function(params) {
    this.set('product', this.modelFor('product'));
    return this.store.find('product', params.product_slug);
  },
  serialize: function(model, params) {
    return { product_slug: model.get('slug') };
  }
});
```

On line 6 we try to find the product by the product_slug.

The serialize method needs to be implemented when an attribute other than id is used for the id. We are telling the Ember that when a product object is passed through the link-to method to use the slug. product_slug will match in the route we are creating below (On line 10):

```js
// app/router.js
import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('product', {path: '/products/:product_slug'});
});
export default Router;
```

The template:

```hbs
{{!-- app/templates/index.hbs --}} 
<h2>{{model.name}}</h2>
<img src={{model.preview}} class="product--image">
<h3>{{model.name}}</h3>
<p>{{model.blurb}}</p>
{{link-to 'Back' 'index' class="btn btn-default"}}
```

[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/686ee06580dc349143b1c72e105356c12ec3916c)

### Error page

If the slug can't be found then Phoenix will return a 404 error. The easiest way to handle this in Ember is create a product-error template which Ember will show automatically.

```hbs
{{!-- app/templates/product-error.hbs --}} 
<h2>Whoops</h2>
<p>This page could not be found.</p>
{{link-to 'Back' 'index' class="btn btn-default"}}
```

[Git commit](https://github.com/acoustep/ember-phoenix-slug-example/commit/4aac158851145c73a24b47ffedf3baae46d37ffd)


## Preview

![Product listing page](http://i.imgur.com/Hlj8Ef5.png "Product listing page")

![Product page](http://i.imgur.com/yflOrbM.png "Product page")

![Whoops 404 page](http://i.imgur.com/iwpxAif.png "Whoops 404 page")

## Summary

In this tutorial we have gone through how to set up ```index``` and ```show``` methods in a Phoenix application to work with URL slugs.

We have connected this API to an Ember application which can view product listings and link to individual product pages.
