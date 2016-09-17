
# ptomulik-portsutil

## Notes for developers

### Cloning the repository

    git clone git://github.com/ptomulik/puppet-portsutil.git

### Installing required gems

    bundle install --path vendor

### Runing unit tests

    bundle exec rake spec

### Building module

    bundle exec rake build

### Generating API documentation

    bundle exec rake yard

The generated documentation goes to `doc/` directory. Note that this works only
under ruby >= 1.9.

### Using vagrant to test some bits manually

    vagrant up freebsd-10.2
    vagrant ssh freebsd-10.2

The actual versions of supported OSes may vary. Please consult `Vagrantfile`.

The project's directory gets copied to `/vagrant` directory of the virtual
machine. The virtual machines created by vagrant may be further deleted with

    vagrant destroy
