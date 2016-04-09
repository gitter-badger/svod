# Svod (Свод)

[![Join the chat at https://gitter.im/svod-music/svod](https://badges.gitter.im/svod-music/svod.svg)](https://gitter.im/svod-music/svod?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![License GPL 3](https://img.shields.io/badge/license-GPL_3-green.svg)](http://www.gnu.org/licenses/gpl-3.0.txt)
[![Build Status](https://travis-ci.org/svod-music/svod.svg?branch=master)](https://travis-ci.org/svod-music/svod)

*Work in progress. If you have questions about the project, please send me
 an email to markkarpov at opmbx dot org.*

* [Overview](#overview)
* [Learn more about the Svod project](#learn-more-about-the-svod-project)
* [Svod packages](#svod-packages)
* [Documentation](#documentation)
* [Running Svod web app locally](#running-svod-web-app-locally)
* [Deploying](#deploying)
* [Contribution](#contribution)
* [License](#license)

This is an open source web application of Svod (Russian: Свод) netlabel
written in Haskell using Yesod web framework.

Although the project is of rather local nature, I nevertheless decided to
write technical descriptions and documentation in English for the following
reasons:

* Some people who do not speak Russian may want to read source code or play
  with the project.

* All Russian developers speak English (or will speak it when they get good
  enough, it's lingua franca anyway, especially in IT).

* I find it difficult to translate all tech terms into Russian and they end
  up sounding extremely nerdy. Well, maybe they are nerdy in English too,
  but…

Presentations, conceptual articles, etc. are on the other hand in Russian
only and there are no plans to translate them.

## Overview

The Svod web application is built to allow (semi-) automatic publication of
audio productions under permissive licenses, such as various flavors of
[Creative Commons](https://creativecommons.org/). The Svod project only
distributes [FLAC](https://xiph.org/flac/) audio and there is no attempt to
make audience pay for it, i.e. it's also free as in “free beer”. Artists can
ask for donations on their profile pages, but it's up to them completely.

In Russia, most part of audience is not willing to pay for music — that's a
fact of today's life. We can make profit only through live performances and
via ads (though no ads will be allowed on the main site). The service is
therefore exists solely to increase visibility of particular artists by
acting as a filter for enormous amount of often amateur content. The filter
is opinionated, but there is no way to avoid this from my point of view.

For artists, the service provides free web storage for their works and
certain popularity boost. This is the first level of “Svod — artist”
relationship. When artist's music achieves certain degree of success as
measured by our team, we can talk about the second level that provides
profit for Svod and for artist as well if he/she wishes to participate on
that level. This includes some management (possibly organization of events
and concerts) and streaming of their music via services that earn money via
selling (targeted) ads.

This repository contains the web application. Main purpose of the
application is to allow any person send us a demo or finished production,
and to allow us examine it and publish it, so users can access it.

The issue tracker can be used for technical issues as well as any other
feedback regarding the service.

## Learn more about the Svod project

If you want to learn more about the project, check out these repos:

* [Collection of presentations about Svod](https://github.com/svod-music/presentations)
* [Conceptual articles as they appear on the site](https://github.com/svod-music/svod-concepts)

You can also open pull requests and actually change the information. Please
think carefully before doing this, but the fact is: we're open to changes
and anyone can propose ideas.

## Svod packages

The Svod web app uses the following packages/resources:

* [Svod core (database and file management abstracted from web)](https://github.com/svod-music/svod-core)
* [Search query mini-language](https://github.com/svod-music/svod-search-query)
* [Linter that prevents suspicious content](https://github.com/svod-music/svod-lint)
* [Database population app for development purposes](https://github.com/svod-music/svod-devel)
* [Twitter intergration](https://github.com/svod-music/twitter-integration)
* [Logo](https://github.com/svod-music/svod-logo)

## Documentation

All components are fully documented, but you will need to generate Haddock
documentation yourself locally. To generate the docs, run the following from
the root of the repo:

```
$ stack haddock
```

If you do not have Stack installed, see the following section that tells how
to setup all the stuff from scratch.

## Running Svod web app locally

This section describes how to set up Svod web app locally and actually play
with it. The application is split into several relatively independent
packages/repos, so it may be not entirely obvious how to make it work. All
instructions here are for Unix-like systems, such as Linux.

First, we need to install PostgreSQL. You should find out how to do this
from repositories of your distro. Arch Linux users can execute this:

```
# pacman -S postgresql
```

We will need a new user (role) and database. By default we use `svod` as
user name and database name, you can choose something different, of course.
In this case edit `config/settings.yml` file and change `user` (`password`)
and `database` attributes of `database` object. Defaults look like this:

```yaml
database:
  user:     "_env:PGUSER:svod"
  password: "_env:PGPASS:svod"
  host:     "_env:PGHOST:localhost"
  port:     "_env:PGPORT:5432"
  database: "_env:PGDATABASE:svod"
  poolsize: "_env:PGPOOLSIZE:10"
```

To create user `svod` and database `svod` (if you have `sudo`):

```
$ sudo -i -u postgres
[postgres]$ initdb --locale $LANG -E UTF8 -D '/var/lib/postgres/data'
[postgres]$ createuser -d svod
[postgres]$ createdb svod -U svod
[postgres]$ exit
```

Now you should have user named `svod` and a database with the same name.

It's time to build the application, but first it's necessary to install some
tools, most importantly GHC (Haskell compiler) and Stack (building tool).
They should be available from your distro's repositories, Arch Linux users
can execute:

```
# pacman -S ghc haskell-stack
$ ghc --version
The Glorious Glasgow Haskell Compilation System, version 7.10.3
$ stack --version
Version 1.0.5, Git revision 9a6f7c965692c437bbe34a67921b0d7d23a95d0c x86_64
```

Visit
[Stack's site](http://docs.haskellstack.org/en/stable/install_and_upgrade/)
to learn more about installation procedure on other platforms. One thing to
note is that you should add `~/.local/bin/` directory to your `PATH` in
order to use programs compiled by Stack from anywhere, add something like
this to your `.bashrc` file:

```
export PATH=$HOME/.local/bin:$PATH
```

Clone the repo and build it (I assume you have Git):

```
$ git clone https://github.com/svod-music/svod.git
$ cd svod
$ stack build # here you can take a beer…
```

To actually run the application you will need some files that are stored in
other repos, so run `perpare.py` from root of the cloned repo (I assume you
have Python 3):

```
$ python prepare.py
```

This just makes sure everything is ready to run. Now you can actually start
the application locally:

```
$ stack exec yesod devel
```

Go to `localhost:3000` in your favorite browser and you should see the main
page. If something does not work, do not hesitate to ask for help in our
Gitter chat (TODO create that chat).

It's often desirable to have some content in the database, so let's populate
it. The most important thing is to register admin account. Primary admin
account always has `"свод"` user name, so you can just register it via UI or
with a simple utility called `svod-devel`:

```
$ git clone https://github.com/svod-music/svod-devel.git
$ cd svod-devel
$ stack build --copy-bins
$ cp -v .svod-devel.ymal ~/
```

Now edit the `~/.svod-devel.yaml` file. If you use non-standard user name
and database name, edit `database` object. `local-svod-root` directory is an
important things to specify now. Go to directory with the web application
repo and inside it you will find directory named `user-content` (it's
created when server is run for the first time, you can also create it
manually). `local-svod-root` should point to this directory, so if my web
app is in `/home/mark/projects/programs/svod/`, I would write:

```
local-svod-root: '/home/mark/projects/programs/svod/user-content/'
```

To populate the database we actually need FLAC files, put around 100
different files (most importantly of different length) under one directory
and specify it in the `.svod-devel.yaml` file, for example:

```
flac-source: '/home/mark/Downloads/flac-factory/'
```

*Please note that not all this functionality is implemented in `svod-devel`
 right now, I will remove this warning when it's done (should be pretty
 soon).*

Now run:

```
$ stack-devel make-admin # if you haven't created one yet
$ stack-devel populate # generate 100 users and 50 releases
```

Now you are done. You can play with the system and start developing your own
features.

## Deploying

TODO

## Contribution

Contributions are very welcome. Do not hesitate to open an issue (even if
it's not technical) or a PR.

## License

Copyright © 2015–2016 Mark Karpov

Distributed under GNU GPL, version 3.
