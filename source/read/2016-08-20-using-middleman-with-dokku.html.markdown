---
title: Using Middleman with Dokku
date: 2016-08-20 13:39 UTC
tags: Middleman, Dokku, Static websites
change_frequency: never
ogp:
  og:
    description: "Realtime chat with Vue.js and Phoenix"
    title: "Realtime chat with Vue.js and Phoenix"
    url: 'read/realtime-chat-with-vue-js-and-phoenix'
---

I Recently started using Dokku for my websites, which has been great for using various versions of languages and frameworks and keeping different versions of dependencies separate.

I wanted to host my blog - which is a static site built with [Middleman](https://middlemanapp.com) - on the same server and came accross [this article](http://thepugautomatic.com/2016/01/static-sites-alongside-dokku-on-digital-ocean/) which I feel is the perfect solution for most static sites, but I needed to add on to it for my own convenience with Middleman.

There's the option of using the [middleman-deploy](https://github.com/middleman-contrib/middleman-deploy) gem, but since there is a fair amount of issues with this gem I decided to try an alternate solution.

As with the previously linked article mentioned, I have made a separate nginx configuration slightly modified to work with Middleman's pretty URL option.

In my ```/etc/nginx/conf.d/static.conf``` file I have the following:

```nginx
server {
  server_name ~^(?<domain>.+)$;
  root /home/static/sites/$domain;
  index index.html index.htm;
  location / {
    try_files $uri $uri/ =404;
    # this makesure pretty urls works with html files without the extension
    default_type "text/html";
    add_header X-Frame-Options SAMEORIGIN;
  }
  location ~ /\.git {
    deny all;
  }

  access_log /var/log/nginx/$domain-static-access.log;

  # error_log can't contain variables, so we'll have to share: http://serverfault.com/a/644898
  error_log /var/log/nginx/static-error.log;
}
```


I made sure my build directory is included in git and then pushed it to Github as a subtree.

```bash
git subtree push --prefix build origin production
```

In my ```static``` website directory on my server I clone the repository and switch to production.

```bash
git clone git@github.com:username/example.git
git checkout production
```

Below is an example of commands I can use to push changes up to production!

```bash
# Your usual git commit workflow
middleman build
git add .
git commit -m "your commit"
git push origin master
# Push update to the production build subtree
git subtree push --prefix build origin production
# SSH into your server, change into the repo directory and run git pull
echo "cd sites/example.com && git pull" | ssh static@example.com /bin/bash
```

After restarting nginx with ```sudo service nginx restart``` everything should work!
