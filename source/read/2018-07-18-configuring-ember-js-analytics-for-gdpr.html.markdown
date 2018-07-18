---
title: Configuring Ember JS Analytics for GDPR
description: "Rails 5.1 comes with a lot changes for Javascript, making it easy to develop apps in Vue, React, and much more. Here's my method for integrating Elm, the functional programming language."
date: 2018-07-18 18:20 UTC
tags: rails, elm, webpack, yarn
change_frequency: never
ogp:
  og:
    description: "Rails 5.1 comes with a lot changes for Javascript, making it easy to develop apps in Vue, React, and much more. Here's my method for integrating Elm, the functional programming language."
    title: "Using Rails 5.1 with Elm"
    url: 'read/using-rails-5-1-with-elm'
---

One of the issues I ran into while developing a new Ember JS app was letting the user configure tracking libraries such as Google Analytics for GDPR compliance.

Fortunately it’s not that difficult! I’ve used two packages for this: [ember-metrics](https://github.com/poteto/ember-metrics) and [ember-local-storage](https://github.com/funkensturm/ember-local-storage). If you’re conservative with your external dependencies then you could get away without using ember-local-storage and just use native Javascript for this. I chose to use it for convenience.

Make sure you install the two above mentioned packages

```bash
ember install ember-local-storage
ember install ember-metrics
```

Add your configuration for ember-metrics in the `config/environment.js` `ENV` hash, here’s mine as an example:

```js
  //...
	metricsAdapters: [
	  {
		name: 'GoogleAnalytics',
		environments: ['development', 'production'],
		config: {
		  id: 'UA-XXXXXXXX-1',
		  anonymizeIp: true,
		  // Use analytics_debug.js in development
		  debug: environment === 'development',
		  // Use verbose tracing of GA events
		  trace: environment === 'development',
		  // Ensure development env hits aren't sent to GA
		  sendHitTask: environment !== 'development',
		  // Specify Google Analytics plugins
		  require: []
		}
	  }
	],
  //...
```

Notice that we’re using `anonymizeIP`. This is a feature of Google Analytics which, you guessed it, anonymises IP addresses. This is optional and will depend on your project’s requirements.

Don’t forget to add the `contentSecurityPolicy` settings if you’re using `ember-content-security-policy` (More about that in the Ember Metrics README).

```js
 //...
 contentSecurityPolicy: {
	  'default-src': "'none'",
	  'script-src': "'self' www.google-analytics.com",
	  'font-src': "'self'",
	  'connect-src': "'self' www.google-analytics.com",
	  'img-src': "'self'",
	  'style-src': "'self'",
	  'media-src': "'self'"
	}
  //...
```

Update your `app/router.js` as instructed on Ember Metrics. We’ll add ember-local-storage to check for the user’s preferences before sending tracking requests as well. I’ve named the storage scope `settings`, however, you can call it what you prefer. See `ember-local-storage` README for details.

Within the `_trackPage()` method we’re checking if `settings.analytics` is set to `true`, if it is then we’ll send the request. You could also make other categories, e.g. `marketing` and send requests for those the same way. 

Ember Metrics supports a bunch of the most popular tools out of the box, including Intercom. You can also add your own custom scripts as well.

```js
import EmberRouter from '@ember/routing/router';
import config from './config/environment';
import { inject as service } from '@ember/service';
import { scheduleOnce } from '@ember/runloop';
import { get } from '@ember/object';
import { storageFor } from 'ember-local-storage';

const Router = EmberRouter.extend({
  // Import ember local storage
  settings: storageFor('settings'),
  location: config.locationType,
  rootURL: config.rootURL,
  metrics: service(),
  didTransition() {
	this._super(...arguments);
	this._trackPage();
  },

  _trackPage() {
	scheduleOnce('afterRender', this, () => {
	  // If user wants analytics then send the request
	  if(this.get('settings.analytics')) {
		const page = this.get('url');
		const title = this.getWithDefault('currentRouteName', 'unknown');
		get(this, 'metrics').trackPage({ page, title });
	  }
	});
  }
});

Router.map(function() {
  // Your routes here
  this.route('login');
  this.route('about');
});

export default Router;

```

Now we’ve got the logic in place but the user has no way of updating their preference unless we expect them to update localStorage via the console (If only!).

There are a bunch of ways you can do this, all we need to do is set the `settings.analytics` in localStorage. I’ve chosen to use a checkbox and I’ve put it on my main `index.hbs` template. We’ll set the variable initially through the `routes/index.js` and watch for updates in `controller/index.js`


```html
//templates/index.hbs
<label>{{input type="checkbox" checked=wantsAnalytics }} Enable Analytics</label>
```

Note that by default we’re setting analytics to `false`. The user will have to opt-in manually to send their analytical data.

```js
//routes/index.js
import Route from '@ember/routing/route';
import { storageFor } from 'ember-local-storage';

export default Route.extend({
  settings: storageFor('settings'),
  setupController(controller) {
	this._super(...arguments)
    // Set default to false to be opt-in, or true to be opt out
	var wantsAnalytics = (this.get('settings.analytics') !== undefined) ? this.get('settings.analytics') : false;
	controller.set('wantsAnalytics', wantsAnalytics);
  },
});

```

In the controller we observe the input checkbox value, once it changes we update the local storage to reflect the new value.

```js
//controllers/index.js
import Controller from '@ember/controller';
import { storageFor } from 'ember-local-storage';

export default Controller.extend({
  settings: storageFor('settings'),
  wantsAnalytics: true,
  updateAnalytics: function() {
	this.set('settings.analytics', this.get('wantsAnalytics'));
  }.observes('wantsAnalytics')
});

```

And that’s all there is to it! You can see this in action on your local environment by opening the developer console. Google Analytics is set to debug mode via Ember Metrics, so you can see when a page view is sent.