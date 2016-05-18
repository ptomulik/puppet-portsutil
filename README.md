# ptomulik-portsutil

[![Build Status](https://travis-ci.org/ptomulik/puppet-portsutil.png?branch=master)](https://travis-ci.org/ptomulik/puppet-portsutil)
[![Coverage Status](https://coveralls.io/repos/ptomulik/puppet-portsutil/badge.png?branch=master)](https://coveralls.io/r/ptomulik/puppet-portsutil?branch=master)
[![Code Climate](https://codeclimate.com/github/ptomulik/puppet-portsutil.png)](https://codeclimate.com/github/ptomulik/puppet-portsutil)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description](#module-description)
3. [Setup](#setup)
    * [What portsutil affects](#what-portsutil-affects)
    * [Setup requirements](#setup-requirements)
4. [Usage](#usage)
5. [Reference](#reference)
6. [Limitations](#limitations)
7. [Development](#development)

## Overview

This library contains extension modules for searching FreeBSD
[ports(7)](http://www.freebsd.org/cgi/man.cgi?query=ports&sektion=7) and
packages. It uses `make search` command to search available ports and
[portversion(1)](http://www.freebsd.org/cgi/man.cgi?query=portversion&manpath=ports&sektion=1)
to query already installed packages. The `portversion` is a part of the
`port-maintenance-tools` package, which may be installed with

```console
pkg install port-maintenance-tools
```

Both, the old [pkg](http://www.freebsd.org/doc/handbook/packages-using.html)
and the new [pkgng](http://www.freebsd.org/doc/handbook/pkgng-intro.html)
databases are supported. The library also allows manipulating build options
(normally set with `make config`) and determining other characteristics of
FreeBSD packaging system.

The library is developed primarily for
[ptomulik-portsng](https://github.com/ptomulik/puppet-portsng)
module, which implements [ports](https://www.freebsd.org/ports/) provider for
package resource.

## Module Description

### Library contents

The library contains the following ruby modules:

- __Puppet::Util::PTomulik::Package::Ports::PortSearch__ - methods for
  searching ports INDEX,
- __Puppet::Util::PTomulik::Package::Ports::PkgSearch__ - search installed
  packages,
- __Puppet::Util::PTomulik::Package::Ports::Functions__ - common stuff used by
  other modules,

and the following classes:

- __Puppet::Util::PTomulik::Package::Ports::Options__ - FreeBSD ports options
  (normally settable by *make search*),
- __Puppet::Util::PTomulik::Package::Ports::PortRecord__ - represents single
  record from ports INDEX,
- __Puppet::Util::PTomulik::Package::Ports::PkgRecord__ - single record from
  package database,
- __Puppet::Util::PTomulik::Package::Ports::Record__ - superclass for PkgRecord
  and PortRecord

The module __Puppet::Util::PTomulik::Package::Ports__ includes both the
__PortSearch__ and __PkgSearch__, so it may be used if you wish to have the
functionality of both modules in your class.

### Library functionality

The __PortSearch__ module provides methods that facilitate searching ports
INDEX for information describing available ports. The __PkgSearch__ module
provides method that facilitate searching the database of installed packages.
It supports the old *pkg* database format and the new *pkgng*. Search methods
in both modules are designed such that they yield one *record* for each package
found in database. The returned record is either __PortRecord__ object (for
__PortSearch__) or __PkgRecord__ (for __PkgSearch__). The record is basically a
`{:field=>value}` hash (the record classes inherit from  __Hash__), but it also
provides some additional methods (see API docs for details). Example fields
that may be found in a record are `:name`, `:pkgname`, `:portorigin`, `:path`,
etc..

Searches are customizable. You may, for example, specify what fields should be
included in search results (in records).

You may search ports INDEX by
[pkgname](#freebsd-ports-collection-and-its-terminology),
[portname](#freebsd-ports-collection-and-its-terminology), by
[portorigin](#freebsd-ports-collection-and-its-terminology), or (with a little
extra effort) perform a custom search by any key supported by the *make search*
command (see
[ports(7)](http://www.freebsd.org/cgi/man.cgi?query=ports&sektion=7)). You may
also perform a heuristic search *by name* without stating whether the *name*
represents *pkgname*, *portname* or *portorigin*  (see API docs for
`search_ports` method).

Installed packages may be searched by *name* (the list of names is passed
directly
[portversion(1)](http://www.freebsd.org/cgi/man.cgi?query=portversion&manpath=ports&sektion=1)).
It's also easy to retrieve information about __all__ installed packages.


When compiling FreeBSD ports, the user has possibility to set some build
options with *make config* command. Here, the same build options may be easily
manipulated with __Options__ class. The __Options__ object represents a set of
options for a single *port*/*package*. The options are implemented as a hash
with simple key/value validation and munging. They may be read from or written
to options files - the ones that normally lay under */var/db/ports/*.

### Terms and definitions

This section explains few terms used across the documentation.

#### FreeBSD ports collection and its terminology

Ports and packages in FreeBSD may be identified by either *portnames*,
*pkgnames* or *portorigins*. We use the following terminology when referring
ports/packages:

  * a string in form `'apache22'` or `'ruby'` is referred to as *portname*
  * a string in form `'apache22-2.2.25'` or `'ruby-1.8.7.371,1'` is referred to
    as a *pkgname*
  * a string in form `'www/apache22'` or `'lang/ruby18'` is referred to as a
    port *origin* or *portorigin*

See [http://www.freebsd.org/doc/en/books/porters-handbook/makefile-naming.html](http://www.freebsd.org/doc/en/books/porters-handbook/makefile-naming.html)

## Setup

### What portsutil affects

This is just a library and shouldn't alter your system (it performs mostly
read-only operations). The __Options__ class writes ports options to options
files, so the contents of options files may change if you save ones. The module
uses Facter and some *read-only* shell commands to query information related to
FreeBSD ports/packages. 

### Setup Requirements

You may need to enable **pluginsync** in your `puppet.conf`.

## Usage

See [Reference](#reference).

## Reference

The complete API documentation may be generated with [yard](http://yardoc.org/)
as follows:

```console
bundle exec rake yard
```

The generated documentation is written to `doc/`. Note that this works only on
ruby >= 1.9.

## Limitations

Nothing that could be currently mentioned.

## Development

The project is held at github:
* [https://github.com/ptomulik/puppet-portsutil](https://github.com/ptomulik/puppet-portsutil)
Issue reports, patches, pull requests are welcome!
