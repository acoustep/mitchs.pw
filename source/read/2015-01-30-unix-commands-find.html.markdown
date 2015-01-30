---
title: "Unix commands: Find"
date: 2015-01-30 13:18 UTC
tags: Unix, Linux, OSX, command line
change_frequency: never
---

After watching one of Gary Bernhardt’s Destroy All Software screencasts I thought I’d take some of his advice and learn about some basic Unix commands.  I’m going to start with ```find```.

This post will be a small collection of useful commands I’ve found.

READMORE

## Basic directory searching

```find .``` - Searching the current directory recursively.

```find ..``` - Search from the parent directory.

```find $HOME``` or ```find ~``` - Search your user directory

```find $HOME/projects/*.js``` - Search for directories and files in your projects directory that end with ```.js``` - Not recursive.

```find $HOME/projects -name *.js``` Search for .js files in your projects directory - recursive.

## Print types

```find . -print0``` - Print the full filename followed by a null character instead of a newline. Best used with files that have multiline filenames.

```find . -printf``` - for formatting output.

Example: Showing filename and access

```find . -name *.js -printf "%p %M\n”```

You can use numbers between %<char> (directives) to align text evenly. ```%100p``` will right align the filename for 100 characters. ```%-100p``` will left align for the same.

Note that this doesn’t work natively on Macs. Instead, you have two options:

* pipe to xargs like so: ```find . -name *.js -print0 | xargs -0 stat -f "%p %k KB”``` (As found from [Stackoverflow](http://stackoverflow.com/questions/752818/why-does-macs-find-not-have-the-option-printf).

* Install Findutils. If you use Homebrew you can run ```brew install findutils```. Note that to use find this way you need to run ```gfind```.

### fprint

Puts the results into a file. This also requires findutils if you’re on a Mac.

```find . -name *.js -fprint all_files.txt```

## Symbolic links

```find -P .``` never follow symbolic links

```find -L .``` follow symbolic links

```find -H .``` don’t follow except when processing command line arguments

## Filter by time

```find . -mmin n``` modified n minutes ago

```find . -mtime n``` modified n*24 hours ago.

```find . -newer ./composer.json``` find files modified after composer.json

## Other filters

```find . -size n[cwbkMG]``` find files that use n units of space. where c = bytes, k = kilobytes, M = megabytes, G = gigabytes

```find . -maxdepth 1``` - Only go one directory deep.

```find . -mindepth 1``` - Ignore the first directory

## Actions

### Delete

```find . -delete``` - delete files in directory

Example - deleting all .js files.

```find . -name *.js -delete```

### Exec

Removing all .bak files:

```find . -name \*.bak -exec rm {} \;```

The curly braces will get replaced with each filename that's found.

As seen [here](http://nixcraft.com/showthread.php/16297-find-exec-bash-example).

## Windows alternative to find

For powershell use ```Find-ChildItem```. [Read more here](http://superuser.com/questions/401495/equivalent-of-unix-find-command-on-windows)

## Useful resources

* [find documentation](http://unixhelp.ed.ac.uk/CGI/man-cgi?find)

* [printf documentation](http://linux.die.net/man/3/printf)
