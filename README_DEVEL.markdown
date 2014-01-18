
# ptomulik-portsutil

## Notes for developers

### Cloning the repository

    git clone git://github.com/ptomulik/puppet-portsutil.git

### Installing required gems

    bundle install --path vendor

### Runing unit tests

    bundle exec rake spec

### Generating API documentation

    bundle exec rake yard

The generated documentation goes to `doc/` directory. Note that this works only
under ruby >= 1.9.

