#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/ptomulik/package/ports'
require 'puppet/util/ptomulik/package/ports/functions'
require 'puppet/util/ptomulik/package/ports/port_search'
require 'puppet/util/ptomulik/package/ports/pkg_search'

describe Puppet::Util::PTomulik::Package::Ports do

  let(:test_class) do
    Class.new do
      extend Puppet::Util::PTomulik::Package::Ports
      def self.to_s; 'Pupept::Util::Package::PortsTest'; end
    end
  end

  specify do
    expect(described_class).to include Puppet::Util::PTomulik::Package::Ports::PortSearch
  end
  specify do
    expect(described_class).to include Puppet::Util::PTomulik::Package::Ports::PkgSearch
  end
end
