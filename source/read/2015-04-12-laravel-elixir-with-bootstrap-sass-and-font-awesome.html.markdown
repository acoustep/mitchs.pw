---
title: Laravel Elixir with Bootstrap SASS and Font Awesome
date: 2015-04-12 09:44 UTC
tags: Laravel, Laravel Elixir, Bootstrap, Font Awesome, SASS
change_frequency: never
ogp:
  og:
    description: "Laravel Elixir with Bootstrap SASS and Font Awesome"
    title: 'Laravel Elixir with Bootstrap SASS and Font Awesome'
    url: 'read/laravel-elixir-with-bootstrap-sass-and-font-awesome'
---

This is my current Gulpfile for Laravel Elixir which is heavily influenced from [this gist](https://gist.github.com/ericbarnes/c3ab73520bae8f1a83a2) and the comments within it.  All I've done is added Font Awesome, set it compile all scripts in ```resources/javascripts``` which is where I keep my own Javascript code and added asset versioning.

```js
// gulpfile.js
var paths = {
'jquery': './vendor/bower_components/jquery/',
'bootstrap': './vendor/bower_components/bootstrap-sass-official/assets/',
'fontawesome': './vendor/bower_components/fontawesome/'
}
 
elixir(function(mix) {
	mix.sass('*', 'public/css/', {includePaths: [paths.bootstrap + 'stylesheets', paths.fontawesome + 'scss']})
		.copy(paths.bootstrap + 'fonts/bootstrap/**', 'public/fonts/bootstrap')
		.copy(paths.fontawesome + 'fonts/**', 'public/fonts/fontawesome')
		.scripts([
			paths.jquery + "dist/jquery.js",
			paths.bootstrap + "javascripts/bootstrap.js",
			'./resources/javascripts/**/*.js',
		], 'public/js/app.js', './')
		.version([
			'css/app.css',
			'js/app.js'
		])
});
```

```js
// bower.json
{
  "name": "Laravel Application",
  "dependencies": {
    "bootstrap-sass-official": "~3.3.1",
    "fontawesome": "~4.3.0"
  }
}
```

```js
// .bowerrc
{
  "directory": "vendor/bower_components"
}
```

Make sure you have Bower installed globally

```
npm install -g bower
```

Install the bower packages

```
bower install
```

After that, you can run the ```gulp watch``` command which will copy Glyphicons and Font Awesome into ```public/fonts```. 

```resources/assets/sass``` and ```resources/javascripts``` will be watched for changes and concatenated into ```public/css/app.css``` and ```public/js/app.js``` respectively.

Your ```resources/assets/sass/app.scss``` should include the following to look for the fonts in the correct place and import their stylesheets.

```scss
$icon-font-path: "/fonts/bootstrap/";
$fa-font-path:   "/fonts/fontawesome";
@import "bootstrap";
@import "font-awesome";
```

That's it! Note that I'm using Elixir's handy asset versioning, too.  In your HTML layout you can use the ```elixir``` function.

```html
	<link href="{{ elixir('css/app.css') }}" rel="stylesheet">
	<script src="{{ elixir('js/app.js') }}"></script>
```
 

