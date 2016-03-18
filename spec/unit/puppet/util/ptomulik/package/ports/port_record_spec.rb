#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/ptomulik/package/ports/port_record'

describe Puppet::Util::PTomulik::Package::Ports::PortRecord do

#  specify { expect(described_class).to be_a Puppet::Util::PTomulik::Package::Ports::Functions }
  specify { expect(described_class).to be < Puppet::Util::PTomulik::Package::Ports::Record }

  describe "::std_fields" do
    specify do
      expect(described_class.std_fields.sort).to eq([
        :bdeps,
        :cat,
        :info,
        :maint,
        :name,
        :path,
        :rdeps,
        :www
      ])
    end
  end

  describe "::default_fields" do
    specify do
      expect(described_class.default_fields.sort).to eq([
        :options_file,
        :path,
        :pkgname,
        :portname,
        :portorigin
      ])
    end
  end

  describe "::deps_for_amend" do
    [
      [:options, [:name, :path]],
      [:options_file, [:name, :path]],
      [:options_files, [:name, :path]],
      [:pkgname, [:name]],
      [:portname, [:name]],
      [:portorigin, [:path]],
      [:portversion, [:name]],
    ].each do |field, deps|
      specify { expect(described_class.deps_for_amend[field]).to eq deps}
    end
  end

  describe "#amend!(fields)" do
    hash = Hash[{:name=>'bar-0.1.2', :path =>'/usr/ports/foo/bar'}]
    context "on #{described_class}[#{hash.inspect}]" do
      subject { described_class[hash] }
      [
        # 1
        [
          [:name, :path],
          {:name=>'bar-0.1.2', :path =>'/usr/ports/foo/bar'}
        ],
        # 1
        [
          [:name, :path, :portorigin],
          {:name=>'bar-0.1.2', :path =>'/usr/ports/foo/bar', :portorigin => 'foo/bar'}
        ],
        # 2
        [
          [:pkgname, :portname, :portorigin],
          {:pkgname=>'bar-0.1.2',:portname=>'bar',:portorigin=>'foo/bar' }
        ],
        # 3
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

  describe "::determine_search_fields(fields,key=nil)" do
    [
      [[:pkgname],              :name, [:name]],
      [[:pkgname, :portname],   :name, [:name]],
      [[:pkgname, :portorigin], :name, [:name, :path]],
      [[:pkgname, :portname],   :path, [:name, :path]],
      [[:portorigin],           :name, [:name, :path]],
      [[:portorigin],            nil,  [:path]],
    ].each do |fields, key, result|
      context "::determine_search_fields(#{fields.inspect},#{key.inspect})" do
        let(:fields) { fields }
        let(:key) { key }
        let(:result) { result }
        specify "should return #{result}" do
          expect(described_class.determine_search_fields(fields,key).sort).to eq result.sort
        end
      end
    end
  end

  describe "::parse(paragraph,options)" do
    [
      # 1.
      [
        [
          'Port:   apache22-2.2.26',
          'Path:   /usr/ports/www/apache22',
          'Info:   Version 2.2.x of Apache web server with prefork MPM.',
          'Maint:  apache@FreeBSD.org',
          'B-deps: apr-1.4.8.1.5.3 autoconf-2.69 autoconf-wrapper-20130530',
          'R-deps: apr-1.4.8.1.5.3 db42-4.2.52_5 expat-2.1.0 gdbm-1.10',
          'WWW:    http://httpd.apache.org/'
        ].join("\n"),
        {},
        {
          :name => 'apache22-2.2.26',
          :path => '/usr/ports/www/apache22',
          :info => 'Version 2.2.x of Apache web server with prefork MPM.',
          :maint => 'apache@FreeBSD.org',
          :bdeps => 'apr-1.4.8.1.5.3 autoconf-2.69 autoconf-wrapper-20130530',
          :rdeps => 'apr-1.4.8.1.5.3 db42-4.2.52_5 expat-2.1.0 gdbm-1.10',
          :www => 'http://httpd.apache.org/'
        }
      ],
      # 2.
      [
        [
          "Port:   audio/akode-plugins-mpeg",
          "Moved:",
          "Date:   2013-10-17",
          "Reason: Removed: Dependency of KDE 3.x"
        ].join("\n"),
        {},
        nil
      ],
      # 3.
      [
        [
          'Port:   audio/akode-plugins-mpeg',
          'Moved:',
          'Date:   2013-10-17',
          'Reason: Removed: Dependency of KDE 3.x'
        ].join("\n"),
        {:moved => true},
        {
          :name => 'audio/akode-plugins-mpeg',
          :moved => '',
          :date => '2013-10-17',
          :reason => 'Removed: Dependency of KDE 3.x'
        }
      ],
      # 4.
      [
        [
          'Port:   print/a2ps-letter',
          'Moved:  print/a2ps',
          'Date:   2013-04-27',
          'Reason: Merged into print/a2ps',
        ].join("\n"),
        {:moved => true},
        {
          :name => 'print/a2ps-letter',
          :moved => 'print/a2ps',
          :date => '2013-04-27',
          :reason => 'Merged into print/a2ps'
        }
      ]
    ].each do |para,options,result|
      context "with paragraph=#{para.inspect}, options=#{options.inspect}" do
        let(:paragraph) { para }
        let(:options) { options }
        let(:result) { result }
        specify "should return #{result.inspect}" do
          expect(described_class.parse(paragraph, options)).to eq result
        end
      end
    end
  end
end

