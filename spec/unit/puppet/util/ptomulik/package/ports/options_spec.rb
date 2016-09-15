#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/ptomulik/package/ports/options'

describe Puppet::Util::PTomulik::Package::Ports::Options do
  # valid option names and values
  describe "#[]= and #[]" do
    [['FOO',:FOO],[:BAR,:BAR], ['0FOO', :"0FOO"]].each do |key,munged_key|
      let(:key) { key }
      let(:munged_key) { munged_key }
      [ ['on',  true],
        [:on,   true],
        [true,  true],
        ['off', false],
        [:off,  false],
        [false, false]
      ].each do |val,munged_val|
        context "#[#{key.inspect}]=#{val.inspect}" do
          let(:val) { val }
          let(:munged_val) { munged_val }
          specify { expect { subject[key] = val }.to_not raise_error }
          context "the returned value" do
            specify { expect((subject[key] = val)).to eq val }
          end
          context "and then #[#{munged_key.inspect}]" do
            specify { subject[key] = val; expect(subject[munged_key]).to eq munged_val }
          end
        end
      end
    end

    # invalid option names
    ['','&^$'].each do |key|
      context "#[#{key.inspect}]=true" do
        let(:key) { key }
        let(:val) { true }
        let(:err) { Puppet::Util::PTomulik::Vash::InvalidKeyError }
        let(:msg) { "invalid option name #{key.inspect}" }
        specify { expect { subject[key] = val }.to raise_error err, msg }
      end
    end

    # invalid option values
    ['',nil,[],{},'offline',:offline,'ontime',:ontime].each do |val|
      context "#[#{:FOO}]=#{val.inspect}" do
        let(:key) { :FOO }
        let(:val) { val }
        let(:err) { Puppet::Util::PTomulik::Vash::InvalidValueError }
        let(:msg) { "invalid value #{val.inspect} for option #{key}" }
        specify { expect { subject[key] = val }.to raise_error err, msg }
      end
    end
  end

  # parse
  describe "#parse" do
    [
      ["=FOO\n", {}],
      ["FOO=\n", {}],
      ["#FOO=BAR\n", {}],
      ["FOO=BAR\n", {}],
      ["FOO+=BAR\n", {}],
      ["OPTIONS_FILE_SET+=FOO\n", {:FOO=>true}],
      ["OPTIONS_FILE_UNSET+=BAR\n", {:BAR=>false}],
    ].each do |str,hash|
      context "#parse(#{str.inspect})" do
        let(:str)  { str }
        let(:hash) { hash }
        specify { expect { described_class.parse(str) }.to_not raise_error }
        specify { expect(described_class.parse(str)).to eq hash }
      end
    end
    ['www_apache22', 'lang_perl5.14'].each do |subdir|
      ['options', 'options.local'].each do |basename|
        file = File.join(my_fixture_dir, "#{subdir}", basename)
        yaml = File.join(my_fixture_dir, "#{subdir}", "#{basename}.yaml")
        next if not File.exists?(file) or not File.exists?(yaml)
        context "#parse(File.read(#{file.inspect}))" do
          let(:options_string) { File.read(file) }
          let(:options_hash)   { YAML.load_file(yaml) }
          specify { expect { described_class.parse(options_string) }.to_not raise_error }
          specify "should return same options as loaded from #{yaml.inspect}" do
            expect(described_class.parse(options_string)).to eq options_hash
          end
        end
      end
    end
  end

  # load
  describe "#load" do
    ['www_apache22', 'lang_perl5.14'].each do |subdir|
      ['options', 'options.local'].each do |basename|
        file = File.join(my_fixture_dir, "#{subdir}", basename)
        yaml = File.join(my_fixture_dir, "#{subdir}", "#{basename}.yaml")
        next if not File.exists?(file) or not File.exists?(yaml)
        context "#load(#{file.inspect})" do
          let(:file) { file }
          let(:options_hash) { YAML.load_file(yaml) }
          specify { expect { described_class.load(file) }.to_not raise_error }
          specify "should return same options as loaded from #{yaml.inspect}" do
            expect(described_class.load(file)).to eq options_hash
          end
        end
      end
    end
    context "#load('inexistent.file')" do
      specify { expect { described_class.load('intexistent.file') }.to_not raise_error}
      specify { expect(described_class.load('inexistent.file')).to eq Hash.new }
    end
    context "#load('inexistent.file', :all => true)" do
      # NOTE: not sure if this doesn't break specs on non-POSIX OSes
      specify { expect { described_class.load('intexistent.file', :all => true) }.
           to raise_error Errno::ENOENT, /No such file or directory/i }
    end

  end

  # query_pkgng
  describe "#query_pkgng(key,packages=nil,params={})" do
    context "#query_pkgng('%o',nil)" do
      let(:cmd) { ['pkg', 'query', "'%o %Ok %Ov'"] }
      specify do
        cmd_str = cmd.join(' ')
        Puppet::Util::Execution.stubs(:execpipe).once.with(cmd_str).yields([
          "origin/foo FOO on",
          "origin/foo BAR off",
          "origin/bar FOO off",
          "origin/bar BAR on"
        ].join("\n"))
        expect(described_class.query_pkgng('%o',nil)).to eq({
          'origin/foo' => described_class[{ :FOO => true, :BAR => false }],
          'origin/bar' => described_class[{ :FOO => false, :BAR => true }]
        })
      end
    end
    context "#query_pkgng('%o',['foo','bar'])" do
      let(:cmd) { ['pkg', 'query', "'%o %Ok %Ov'", 'foo', 'bar'] }
      specify do
        cmd_str = cmd.join(' ')
        Puppet::Util::Execution.stubs(:execpipe).once.with(cmd_str).yields([
          "origin/foo FOO on",
          "origin/foo BAR off",
          "origin/bar FOO off",
          "origin/bar BAR on"
        ].join("\n"))
        expect(described_class.query_pkgng('%o',['foo','bar'])).to eq({
          'origin/foo' => described_class[{ :FOO => true, :BAR => false }],
          'origin/bar' => described_class[{ :FOO => false, :BAR => true }]
        })
      end
    end
  end

  # generate
  describe "#generate(params)" do
    [
      # 1.
      [
        described_class[ {:FOO => true, :BAR =>false} ],
        {},
        [
          "# This file is auto-generated by puppet\n",
          "OPTIONS_FILE_UNSET+=BAR\n",
          "OPTIONS_FILE_SET+=FOO\n"
        ].join("")
      ],
      # 2.
      [
        described_class[ {:FOO => true, :BAR =>false} ],
        {:pkgname => 'foobar-1.2.3'},
        [
          "# This file is auto-generated by puppet\n",
          "# Options for foobar-1.2.3\n",
          "_OPTIONS_READ=foobar-1.2.3\n",
          "OPTIONS_FILE_UNSET+=BAR\n",
          "OPTIONS_FILE_SET+=FOO\n",
        ].join("")
      ]
    ].each do |obj,params, result|
      context "#{obj.inspect}.generate(#{params.inspect}" do
        let(:params) { params }
        let(:result) { result }
        subject { obj }
        specify { expect(subject.generate(params)).to eq result}
      end
    end
  end

  # save
  describe "#save" do
    dir = '/var/db/ports/my_port'
    str = "# This file is auto-generated by puppet\n"
    let(:dir) { dir }
    let(:str) { str }
    context "when #{dir} exists" do
      context "#save('#{dir}/options')" do
        before(:each) do
          File.stubs(:exists?).with(dir).returns true
          Dir.expects(:mkdir).never
          FileUtils.expects(:mkdir_p).never
        end
        specify do
          File.stubs(:open)
          expect { subject.save("#{dir}/options") }.to_not raise_error
        end
        specify "should call File.open('#{dir}/options','w') { |f| f.write(#{str.inspect}) } once" do
          testobj = Class.new { }
          testobj.expects(:write).once.with(str)
          File.expects(:open).once.with("#{dir}/options", 'w').yields(testobj).then.returns(6)
          expect(subject.save("#{dir}/options")).to eq 6
        end
      end
      context "#save('#{dir}/options', :pkgname => 'foo-1.2.3')" do
        str2 = str
        str2 += "# Options for foo-1.2.3\n"
        str2 += "_OPTIONS_READ=foo-1.2.3\n"
        let(:str2) { str2 }
        before(:each) do
          File.stubs(:exists?).with(dir).returns true
          Dir.expects(:mkdir).never
          FileUtils.expects(:mkdir_p).never
        end
        specify do
          File.stubs(:open)
          expect { subject.save("#{dir}/options", :pkgname => 'foo-1.2.3') }.to_not raise_error
        end
        specify "should call File.open('#{dir}/options','w') { |f| f.write(#{str2.inspect}) } once" do
          testobj = Class.new { }
          testobj.expects(:write).once.with(str2)
          File.expects(:open).once.with("#{dir}/options", 'w').yields(testobj).then.returns(9)
          expect(subject.save("#{dir}/options", :pkgname => 'foo-1.2.3')).to eq 9
        end
      end
    end
    context "when #{dir} does not exist" do
      context "#save('#{dir}/options')" do
        before(:each) do
          File.stubs(:exists?).with(dir).returns false
          FileUtils.expects(:mkdir_p).never
        end
        specify do
          Dir.stubs(:mkdir)
          File.stubs(:open)
          expect { subject.save("#{dir}/options") }.to_not raise_error
        end
        specify "should call Dir.mkdir('#{dir}') and " +
           "then File.open('#{dir}','w') { |f| f.write(#{str.inspect}) }" do
          save_seq = sequence('save_seq')
          testobj = Class.new { }
          Dir.stubs(:mkdir).once.with(dir).in_sequence(save_seq)
          File.stubs(:open).once.with("#{dir}/options",'w').in_sequence(save_seq).yields(testobj).then.returns(12)
          testobj.expects(:write).once.with(str).in_sequence(save_seq)
          expect(subject.save("#{dir}/options")).to eq 12
        end
      end
    end
    context "when #{dir} does not exist" do
      context "#save('#{dir}/options', :mkdir_p => true)" do
        before(:each) do
          File.stubs(:exists?).with(dir).returns false
          Dir.expects(:mkdir).never
        end
        specify { expect {
          FileUtils.stubs(:mkdir_p)
          File.stubs(:open)
          subject.save("#{dir}/options", :mkdir_p => true)
        }.to_not raise_error }
        specify "should call FileUtils.mkdir_p('#{dir}') and " +
           "then File.write('#{dir}',#{str.inspect})" do
          save_seq = sequence('save_seq')
          testobj = Class.new { }
          FileUtils.stubs(:mkdir_p).once.with(dir).in_sequence(save_seq)
          File.stubs(:open).once.with("#{dir}/options",'w').in_sequence(save_seq).yields(testobj).then.returns(15)
          testobj.expects(:write).once.with(str).in_sequence(save_seq)
          expect(subject.save("#{dir}/options", :mkdir_p => true)).to eq 15
        end
      end
    end
  end
end
