---
title: Using Middleman with Dokku - Updated
date: 2018-01-31 12:37 UTC
tags: Middleman, Dokku, Static websites
change_frequency: never
ogp:
  og:
    description: "Using Middleman with Dokku - Updated"
    title: "Using Middleman with Dokku - Updated"
    url: 'read/using-middleman-with-dokku-updated'
---

In a previous blog post I explained how to set up a Middleman blog alongside Dokku. Since then I’ve found a better approach which uses `middleman-deploy`.

Full credit to this [Github thread](https://github.com/dokku/dokku/issues/1427) which pointed me to the right path.

First add your new Dokku app on your server the same way you’d set up any Dokku app.

```bash
dokku apps:create example-url.com
```

In your local version add middleman deploy to your Gemfile

[https://github.com/middleman-contrib/middleman-deploy](https://github.com/middleman-contrib/middleman-deploy)

Use these settings in your `confir.rb`

```ruby
activate :deploy do |deploy|
	deploy.deploy_method = :git
	deploy.remote = 'dokku@<serverip>:example-url.com'
	deploy.branch = 'master'
end
```

Note that in Middleman v3 you should use `method` and in v4 you should use `deploy_method`

Make sure to add Dokku as a remote git on your local Middleman project

```bash
git remote add dokku dokku@<serverip>:example-url.com
```

In the `source` dir add these two files

`Procfile`

```
web: vendor/bin/heroku-php-nginx -C nginx.conf
```

`composer.json`

```
{}
```

Running build will then put both files in the `build` which is where Dokku will find them.

To deploy, simply commit to git and run 

```bash
Bundle exec middleman deploy
```

That's all there is to it. Except perhaps one caveat!

```bash
Can't deploy! Please add a remote with the name 'dokku@<serverip>:example-url.com' to your repo
```

There are a couple of issues at play here, and it's to do with the middleman-deploy gem. Here's the quick fix:

You will need to modify the gem code, do this either by using a `git clone`, and setting the `path:` in your Gemfile to your local version. Or (and not recommended) use `bundle show middleman-deploy` to get the gem location on your computer.

In the file named `lib/middleman-deploy/strategies/git/force_push.rb` comment out these lines

```ruby
unless remote =~/\.git$/
	url = `git config --get remote.#{url}.url`
end
```

If your using the name 'dokku' instead of the full remote url in the `config.rb`, change the remote from `dokku` to the full git remote address.

Alternatively to modifying the `middleman-deploy` code, you can name your dokku project ending with `.git`.
