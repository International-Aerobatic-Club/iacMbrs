This is a utility to download a file from a very specific file server.
If you don't know what it is, it isn't really of interest to you.

We can maintain it as open source because most of the details are contained
in the config file, `config.yml` which is not part of this repository.

And never mind why a secure scp, sftp, https download isn't available.
Never mind that the content isn't available through a secure API.
That's just the way it is.

The config file contains a hash serialized in
[YAML](http://yaml.org/spec/1.1/current.html) format.

The contents of the config file are as follows:

- url: location of the interface
- uname: user name
- pwd: password
- dom: a domain
- filename: name of the file to retrieve
- download_to: the location where you want to save the file

In order to use this:

- Have a ruby interpreter.
Find the version of ruby used for development captured in the file, ".ruby-version".
- Install the bundler gem: `gem install bundler`
- Install the required gems: `bundle install`
- Prepare a config file named, "config.yml".
- Run the script: `ruby retrieveList.rb`
