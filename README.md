Integrity-Knife
===

This repository is a [Chef](http://www.opscode.com/chef/) project designed to quickly and easily set up a fully-functioning [Integrity](http://integrity.github.io/) application on a server of your choosing. 

**Please note that this repository is still a work in progress as I continue bugfixing the deployment process. Feel free to use it as a base for other work, but do not expect the project to work start-to-finish just yet**

The project delegates install tasks to other recipes as much as possible, and uses the fantastic [application_ruby](https://github.com/opscode-cookbooks/application_ruby) cookbook for most of the work setting up the deployment.

Guide to the Project:
---

If you haven't used Chef before, this is a pretty simple project to get started on - though I'm still learning myself!

* **Cheffile:** This is the `Gemfile` of Chef - it uses a handy gem called `librarian` to 'bundle' cookbooks into the project from around the Internet. To add a cookbook, just add the line in the `Cheffile` and run `librarian-chef install` to update the `cookbooks` directory.
* **Gemfile:** This just bundles in `librarian` and `chefspec`, for satisfying Chef dependencies and running tests respectively.
* **cookbooks:** Where `librarian` downloads cookbooks to, and where Knife reads them from for processing
* **data_bags:** Not used at the moment, but meant for holding config data
* **nodes:** can have information for different hosts - for example `app1.example.com` might have a node file listing it's role as `application`, `db1.example.com` might have a node file listing it's role as `database`. Since Integrity is quite capable of running on a single server, we just have a `default` node that defines what recipes we should run when we run `chef`.
* **roles:** as alluded to, roles are files that represent a 'type' of server. For example, you might have a role for an application server, a role for a web server and a role for a database server.
* **site-cookbooks:** not a formal location in a Chef project, but generally where 'bespoke' (that is, cookbooks you've thrown together yourself) cookbooks live. There's just one cookbook in this project - `integrity`, that has a single recipe called `integrity::default`. This recipe just calls everything else to install necessary packages, set up users and settings etc.
* **spec:** where specs for `integrity::default` live. It's important to keep these specs up to date, even though there's a lot of duplication, as it ensures that the recipe continues to fulfill it's requirements (it's  'spec' if you will).
* **Vagrantfile:** stores configuration to boot a virtual machine and install the chef recipes on it with [vagrant](http://www.vagrantup.com/). For more on this, see _Testing_. For those adventurous types, you could also use this Vagrantfile to [set up a Digital Ocean server](https://github.com/smdahlen/vagrant-digitalocean).

Testing:
---

If you'd like to see how chef works, or make sure that this recipe sets up Integrity according to your wishes, a `Vagrantfile` is included that will set up a virtual machine on your computer and run the chef recipes against that virtual machine - no server required! To test out the recipe, simply [install Vagrant](http://downloads.vagrantup.com/), clone this project, `cd` into the directory, and run `vagrant box add precise64 http://files.vagrantup.com/precise64.box` then `vagrant up` to download a base Ubuntu image, set up and start the VM, and run this chef recipe against it. Once the chef recipe has finished running, you may also run `vagrant ssh` to log in to the running VM.

You can continue to use this `vagrant up` method to test the recipe while you change how the recipe works, if you wish - if you screw things up, just run `vagrant destroy` and then `vagrant up` again to re-create the machine from scratch. 

Running for reals:
---

You can also run this chef recipe on a server really easily using [knife solo](http://matschaffer.github.io/knife-solo/). Knife Solo installs chef on your server, uploads this project, and then runs it straight on the server - it's as simple as that. 

To install Integrity on a server, simply ensure `knife solo` is installed (`gem install knife-solo`), and then run:

``` bash
knife solo bootstrap user@ip nodes/default.json
```

…and wait for it to complete (if you haven't got public key access set up, you will need to enter your server password 4 or 5 times during the run.)

If you're reading this, and the documentation for this section seems a little sparse, please log an issue on the Github project and remind me - I haven't yet finished writing the recipe, and I've likely forgotten to come back and add more detail.


Running Tests:
---

Integrity-Knife uses [chefspec](https://github.com/acrmp/chefspec) to write specs to ensure that the main `integrity::default` recipe functions as we need it to. Right now the tests for this are quite basic, but it ensures that the recipe establishes a server with the basic requirements necessary for running Integrity.

To see how the specs for the project are written, check out `spec/integrity/default_spec.rb`. To run the specs for yourself, run `rake`. You don't need any virtual machines or anything set up for this, just make sure you've run `bundle install` so that `chefspec` is installed. 

Notes:
---

* The server includes a number of recipes designed to provide a measure of security, including a firewall (`ufw`), fail2ban, and automatic security updates. If you're having access troubles, you might want to investigate these
* `application_ruby` does a lot of magic, so it's worth having a dig into to make sure you understand what's going on.
* The recipe creates an application user called 'integrity' to run the application and own folders, etc. If you're testing using Vagrant and you run `vagrant ssh`, you'll start logged in as the 'vagrant' user - you might want to run `sudo su integrity` to log in as the application user.
* **Right now Chef 11 doesn't fully support Ruby 2.0.0 so I suggest that you run this project on Ruby 1.9.3 for now.**
* Many recipes are spitting out warnings about bits and pieces - this is mostly because Chef 11 is quite recent and has deprecated a number of features and ways of doings things that recipes haven't quite caught up to yet. Because the `Cheffile` doesn't lock to certain versions, running `librarian-chef install` should hopefully resolve some of these warnings as they are fixed upstream - but for now, there's a lot of unnecessary output when running tests.


License:
---

MIT License. See LICENSE.txt for details.