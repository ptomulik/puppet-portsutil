#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/ptomulik/package/ports/pkg_record'

describe Puppet::Util::PTomulik::Package::Ports::PkgRecord do

#  specify { expect(described_class).to be_a Puppet::Util::PTomulik::Package::Ports::Functions }
  specify { expect(described_class).to be < Puppet::Util::PTomulik::Package::Ports::Record }

  describe "::std_fields" do
    specify do
      expect(described_class.std_fields.sort).to eq([
        :pkgname,
        :portinfo,
        :portorigin,
        :portstatus
      ])
    end
  end

  describe "::default_fields" do
    specify do
      expect(described_class.default_fields.sort).to eq([
        :options,
        :options_file,
        :options_files,
        :pkgname,
        :pkgversion,
        :portinfo,
        :portname,
        :portorigin,
        :portstatus
      ])
    end
  end

  describe "::deps_for_amend" do
    [
      [:options, [:portname, :portorigin]],
      [:options_file, [:portname, :portorigin]],
      [:options_files, [:portname, :portorigin]],
      [:pkgversion, [:pkgname]],
    ].each do |field, deps|
      specify { expect(described_class.deps_for_amend[field]).to eq deps}
    end
  end

  describe "#amend!(fields)" do
    hash = Hash[{:pkgname=>'bar-0.1.2', :portorigin=>'foo/bar22'}]
    context "on #{described_class}[#{hash.inspect}]" do
      subject { described_class[hash] }
      [
        # 1
        [
          [:portname, :pkgversion],
          {:portname => 'bar', :pkgversion => '0.1.2'}
        ],
        # 2
        [
          [],
          { }
        ],
      ].each do |fields, result|
        context "#amend!(#{fields.inspect})" do
          let(:fields) { fields }
          let(:result) { result }
          specify "changes self to #{result.inspect}" do
            s = subject
            s.amend!(fields)
            expect(s).to eq result
          end
        end
      end
    end
  end
end

