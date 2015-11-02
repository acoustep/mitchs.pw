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

There is no special configuration required for each to work together. Although, I recommend launching Ember with the proxy argument as shown below.

```bash
ember serve --proxy=http://localhost:4000
```

This means you don't have to worry about Content Security Policy between Ember and your API.

If you haven't already, check out Maxwell Holder's [Build a Blog with Phoenix and Ember.js](http://maxwellholder.com/blog/build-a-blog-with-phoenix-and-ember). This article really helped me get started with using Ember and Phoenix together.

I'll be demonstrating how to set up a product index which links through to product pages with a slug instead of an ID. This includes querying the slug on the API as well.

## Setting up Phoenix

Phoenix provders a really useful generator for APIs. Run the following command to get the cruft of the work done for you

```bash
mix phoenix.gen.json Product products name:string slug:string blurb:text preview:string featured:boolean
```

The above command generates the view, controller, migration and model files.

To make this accessible we need to add resource to the router.

```elixir
# web/router.ex
scope "/api", App do 
  pipe_through :api
  resources "/products", ProductController, only: [:index, :show]
end
```

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
defmodule App.ProductView do
  use App.Web, :view

  def render("index.json", %{products: products}) do
    %{products: render_many(products, App.ProductView, "product.json")}
  end

  def render("show.json", %{product: product}) do
    %{product: render_one(product, App.ProductView, "product.json")}
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

On line 1 ```id``` has been altered to say ```slug```, this is just so we're clear that we're dealing with a slug. The map key is still ```id``` as the product resource route added previously is set up to pattern match for ```id```. To change it to ```slug``` requires adding a separate route.

Lines 2 to 4 is the query to find the slug in the database.

Line 5 uses Repo.one! to fetch the first match for the query or throw an error.

### CORS in production
