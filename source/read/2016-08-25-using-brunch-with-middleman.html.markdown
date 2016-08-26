---
title: Using Brunch with Middleman
date: 2016-08-25 13:23 UTC
tags: Middleman, Brunch
change_frequency: never
ogp:
  og:
    description: "Using Brunch with Middleman v4"
    title: "Using Brunch with Middleman"
    url: 'read/using-brunch-with-middleman'
---

I recently started a new blog in an area unrelated to Web Development and was pleased to find that with the release of Middleman v4 you can now specify your own external asset pipeline.

I decided to give Brunch a shot - since I already use it with Elixir's Phoenix Framework and I was pleasantly surprised by how easy it was to get everything set up.

First of all, here's my ```package.json``` file - note that Bourbon, Bourbon Neat, Turbolinks, and Font Awesome are all optional but will help provide an example of how to set up various libraries with Brunch and Middleman.

```json
{
  "name": "middlemanblog",
  "version": "1.0.0",
  "description": "",
  "main": "brunch-config.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "MIT",
  "devDependencies": {
    "brunch": "^2.8.2",
    "css-brunch": "~2.0.0",
    "clean-css-brunch": "~2.0.0",
    "copycat-brunch": "^1.1.0",
    "sass-brunch": "^1.9.2",
    "javascript-brunch": "~2.0.0",
    "uglify-js-brunch": "~2.0.1",
    "node-bourbon": "^4.2.8",
    "bourbon-neat": "^1.8.0",
    "font-awesome": "^4.6.3",
    "turbolinks": "^5.0.0"
  },
  "dependencies": {
    "babel-brunch": "^6.0.6"
  }
}
```

All of the Brunch libraries are copied over from Phoenix's set up.

* ```css-brunch``` adds CSS support to brunch
* ```clean-css-brunch``` minifys CSS
* ```sass-brunch``` adds SASS support
* ```copycat-brunch``` is for copying files (in this case for copying font files to a new directory)
* ```javascript-brunch``` adds javascript support
* ```uglify-js-brunch``` minifys the Javascript

Here's the ```brunch-config.js```

```js
exports.config = {
	overrides: {
		production: {
			paths: {
				public: "build"
			}
		}
	},
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "javascripts/all.js"
    },
    stylesheets: {
      joinTo: "stylesheets/site.css",
      order: {
        after: ["source/stylesheets/site.css.scss"] // concat app.css last
      }
    },
    templates: {
      joinTo: "javascripts/all.js"
    }
  },

  conventions: {
    assets: /^(source\/assets)/
  },

  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "source/javascripts",
      "source/stylesheets",
      "source/assets",
      "test/static"
    ],

    // Where to compile files to
    public: ".tmp/dist"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/source\/vendor/],
			presets: ['es2015', 'es2016']
    },
    sass: {
      debug: 'comments',
      options: {
        includePaths: [
          "node_modules/bourbon/app/assets/stylesheets", 
          "node_modules/font-awesome/scss",
          "node_modules/bourbon-neat/app/assets/stylesheets"
        ], // tell sass-brunch where to look for files to @import
        precision: 8 // minimum precision required by bootstrap-sass
      }
    },
    copycat: {
      "fonts": ["node_modules/font-awesome/fonts"] 
    }
  },

  modules: {
    autoRequire: {
      "javascripts/all.js": ["source/javascripts/all"]
    }
  },
  npm: {
    enabled: true,
    whitelist: ["turbolinks"],
    globals: {
      $: 'jquery',
      jQuery: 'jquery'
    }
  }
};
```

In the ```overrides``` section you can see that the ```public``` directory is changed to ```build``` instead of ```.tmp/dist``` which is used in development. This is because when you run ```middleman build``` you'll want the files in the build directory and when you run ```middleman server``` you'll want them in ```.tmp/dist```.

Watches are set to various asset directories to auto reload. You could also watch the whole source directory for changes if you so wish.

Copycat copies the Font Awesome font files to the appropriate directory

Javascript is set to allow for es2016 code so you can use various Javascript goodies in your code.

The only thing I can't get working is SASS include paths. Even though they are set here, Brunch refuses to find them when imported. This is easy enough to get around by including the relative path in the SASS files which I'll show in a moment.

Here's the relevant snippet of configuration for ```config.rb```

```ruby
activate :external_pipeline,
  name: :brunch,
  command: build? ? './node_modules/brunch/bin/brunch build --production --env production' : './node_modules/brunch/bin/brunch watch --stdin',
  source: ".tmp/dist",
  latency: 1
```

Here's how my SASS ```source/stylesheets/site.css.scss``` looks. Note that ```$icon-font-path``` is important for Font Awesome to find the fonts in the appropriate directory.

```sass
@charset "utf-8";
// @import "normalize";
$icon-font-path: "/fonts/";
$font-stack-system: "helvetica";
@import "../../node_modules/bourbon/app/assets/stylesheets/bourbon";
@import "../../node_modules/bourbon-neat/app/assets/stylesheets/neat-helpers";
@import "../../node_modules/bourbon-neat/app/assets/stylesheets/neat";
// @import "base/base"; // This is only for Bourbon Bitters
@import "../../node_modules/font-awesome/scss/font-awesome";
```

Bootstrap and Foundation can both be used in the exact same way as Bourbon. Just locate the main SASS file in your ```node_modules``` directory and import!

Example ```source/javascripts/all.js```

```js
import "turbolinks";

console.log('hello world :)');
```

There you have it! Have fun using Middleman and Brunch!
