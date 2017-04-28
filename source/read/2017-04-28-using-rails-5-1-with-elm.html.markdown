---
title: Using Rails 5.1 with Elm
description: "Rails 5.1 comes with a lot changes for Javascript, making it easy to develop apps in Vue, React, and much more. Here's my method for integrating Elm, the functional programming language."
date: 2017-04-28 20:18 UTC
tags: rails, elm, webpack, yarn
change_frequency: never
ogp:
  og:
    description: "Rails 5.1 comes with a lot changes for Javascript, making it easy to develop apps in Vue, React, and much more. Here's my method for integrating Elm, the functional programming language."
    title: "Using Rails 5.1 with Elm"
    url: 'read/using-rails-5-1-with-elm'
---

Rails 5.1 comes with a lot changes for Javascript, making it easy to develop apps in Vue, React, and much more.

After a bit of playing around, here's how I've set up Elm with Webpack.

First make sure you have Rails 5.1 installed and Elm 0.18.  This method will expect to use elm-make via webpack, so make sure it's available in your path. Webpacker also requires Node 6.4+, so make sure you have that installed, too.

Create a new rails app with --webpack


```
rails new app —webpack
```

Change in to the app directory and add the following Node packages with Yarn:

```
bin/yarn add elm elm-webpack-loader elm-hot-loader
```

Next we'll add the Foreman gem. This gem let's us use the webpack-dev-server alongside Rails.

```
# Gemfile
gem 'foreman'
```

Run ```bundle update``` afterwards to install the gem.

Create a ```Procfile``` in your project root for Foreman with the following 2 lines of code:

```
web: ./bin/rails server
webpack: ./bin/webpack-dev-server
```

Now we need to tell Webpack to look for .elm files. Go to ```config/webpack/paths.yml``` and add ```- .elm``` to the list (Note that order _does_ matter, Putting .elm above .js will throw an error).


```yml
default: &default
  config: config/webpack
  entry: packs
  output: public
  manifest: manifest.json
  node_modules: node_modules
  source: app/javascript
  extensions:
    # ...
    - .coffee
    - .js
    - .elm
```

Go into the loaders directory and add ```elm.js``` with the following code:

```js
//config/webpack/loaders/elm.js

module.exports = {
  test: /\.elm$/,
  exclude: [/elm-stuff/, /node_modules/],
  loader: 'elm-hot-loader!elm-webpack-loader?verbose=true&warn=true&debug=true'
}
```

Notice in line 6 that you can configure verbosity, warnings and debugging.

Finally, it's time to write some Elm! In your ```app/javascript/packs/``` directory create ```Main.elm``` and add this basic Elm code.

```elm
module Main exposing (..)

import Html
import String


main : Html.Html msg
main =
    "Hello World"
        |> Html.text
```

In the adjacent application.js file (Still in the packs directory) import your Elm file and embed it in the div element of your choice.

```js
var Elm = require('./Main');
Elm.Main.embed( document.getElementById( 'app' ) );
```

Go to your application layout (app/views/layouts/application.html.erb) and import the Javascript file with the Webpack helper just above your closing body tag and add the div element wherever you wish.

```html
    <!-- ... -->
    <div id="app"></div>
    <%= javascript_pack_tag 'application' %>
  </body>
```

You'll need the ```elm-package.json``` to run the server, so go ahead and run ```elm-package install``` which will generate that for you.



All you need now is a view to display it in! If you haven't done this already, you can quickly create a route in ```config/routes.rb```

```ruby
get '/', to: 'application#index'
```

Then create view ```app/views/application/index.html.erb```, if you put the div in the application layout, then you should now be able to see "Hello World" from Elm!
