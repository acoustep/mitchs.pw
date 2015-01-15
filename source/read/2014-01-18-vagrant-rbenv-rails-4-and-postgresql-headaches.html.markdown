---
title: Vagrant, RBENV, Rails 4 and PostgreSQL headaches
date: 2014-01-18 00:00 UTC
tags: Rails 4, Rbenv, PostgreSQL, Postgres, Vagrant
change_frequency: never
---

**Forewarning:** This post is more of a rambling and future reference to myself.

I've been working on a project in Ruby on Rails for a little while and a few days ago I made the mistake of upgrading to OS X Mavericks with the thoughts "What's the worst that could happen?" running through my mind.

Well for some reason the PG gem really doesn't like my computer anymore.  Long story short I decided that I would fire up a Ubuntu development environment on Vagrant and well, it has been a difficult ride.

To keep it short.  First time around I had many issues.

READMORE

Vagrant was making rails take forever to download.  The solution to this can be found here:

[https://github.com/rubygems/rubygems/issues/513](https://github.com/rubygems/rubygems/issues/513)

TL;DR: Add this to your vagrant file and restart it.

```ruby
config.vm.provider "virtualbox" do |vb|
  vb.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
  vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
end
```

Make sure you ```rbenv rehash``` after installing both Ruby and Rails.

After mucking up with Nokogiri and PG dependancies I hit a wall with folder permissions and Bundler.

I decided to start again following this guide:

[http://gorails.com/setup/ubuntu/13.10](http://gorails.com/setup/ubuntu/13.10)

This went much smoother, installing all dependences beforehand.  Note that Adding a new Repository to Ubuntu didn't work without first running

```bash
sudo apt-get update
sudo apt-get install software-properties-common
sudo apt-get install python-software-properties
```

But besides that everything worked fine. Bundle install worked with no issues which makes me very happy!

My final issue was creating and migrating the database via rake.  

```ruby
PG::InvalidParameterValue: ERROR:  encoding "UTF8" does not match locale "en_US"
DETAIL:  The chosen LC_CTYPE setting requires encoding "LATIN1".
```

This was a real pain and seemed to be a default for PostgresSQL conflicting with Rails.

To fix I logged into psql with ```sudo su postgres -c psql``` and followed the advise posted by tokhi on Stackoverflow [https://stackoverflow.com/questions/16736891/pgerror-error-new-encoding-utf8-is-incompatible](https://stackoverflow.com/questions/16736891/pgerror-error-new-encoding-utf8-is-incompatible)

Or alternatively this post: [https://marcinraczkowski.wordpress.com/2013/03/13/fixing-incorrect-postgresql-locale/](https://marcinraczkowski.wordpress.com/2013/03/13/fixing-incorrect-postgresql-locale/)

Now it all works and hopefully this will resolve any future issues I have with rails deployments!

