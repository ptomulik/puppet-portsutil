#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/ptomulik/package/ports/functions'

describe Puppet::Util::PTomulik::Package::Ports::Functions do
  let(:test_class) do
    Class.new do
      extend Puppet::Util::PTomulik::Package::Ports::Functions
      def self.to_s; 'Pupept::Util::Package::Ports::FunctionsTest'; end
    end
  end

  version_pattern = '[a-zA-Z0-9][a-zA-Z0-9\\.,_]*'

  describe "#{described_class}::PORTNAME_RE" do
    specify { expect(described_class::PORTNAME_RE).to eq /[a-zA-Z0-9][\w\.+-]*/ }
  end

  describe "#{described_class}::PORTVERSION_RE" do
    specify { expect(described_class::PORTVERSION_RE).to eq /[a-zA-Z0-9][\w\.,]*/ }
  end

  describe "#{described_class}::PKGNAME_RE" do
    specify do
      portname_re = described_class::PORTNAME_RE
      portversion_re = described_class::PORTVERSION_RE
      expect(described_class::PKGNAME_RE).to eq /(#{portname_re})-(#{portversion_re})/
    end
  end

  describe "#{described_class}::PORTORIGIN_RE" do
    specify do
      portname_re = described_class::PORTNAME_RE
      expect(described_class::PORTORIGIN_RE).to eq /(#{portname_re})\/(#{portname_re})/
    end
  end

  describe "#escape_pattern(pattern)" do
    [
      ['abc()?', 'abc\\(\\)?'],
      ['file.name', 'file\\.name'],
      ['foo[bar]', 'foo\\[bar\\]'],
      ['foo.*', 'foo\\.\\*'],
      ['fo|o', 'fo\\|o'],
    ].each do |pattern, result|
      let(:pattern) { pattern }
      let(:result) { result }
      context "#escape_pattern(#{pattern.inspect})" do
        specify { expect(test_class.escape_pattern(pattern)).to eq result }
      end
    end
  end

  describe "#strings_to_pattern(string)" do
  [
      [ 'abc()?', 'abc\\(\\)?'],
      [ 'foo.bar[geez]', 'foo\\.bar\\[geez\\]' ],
      [ ['foo', 'bar', 'geez'], '(foo|bar|geez)'],
      [ ['foo.*', 'b|ar', 'ge[]ez'], '(foo\\.\\*|b\\|ar|ge\\[\\]ez)']
    ].each do |string, result|
      let(:string) { string }
      let(:result) { result }
      context "#strings_to_pattern(#{string.inspect})" do
        specify { expect(test_class.strings_to_pattern(string)).to eq result }
      end
    end
  end

  describe "#fullname_to_pattern(names)" do
    [
      [ 'apache22-2.2.26', '^apache22-2\\.2\\.26$' ],
      [
        ['php5-5.4.21', 'apache22'],
        '^(php5-5\\.4\\.21|apache22)$'
      ]
    ].each do |names, result|
      let(:names) { names }
      let(:result) { result }
      context "#fullname_to_pattern(#{names.inspect})" do
        specify { expect(test_class.fullname_to_pattern(names)).to eq result }
      end
    end
  end

  describe "#portorigin_to_pattern(names)" do
    [
      [ 'www/apache22', '^/usr/ports/www/apache22$' ],
      [
        ['lang/php5', 'www/apache22'],
        '^/usr/ports/(lang/php5|www/apache22)$'
      ]
    ].each do |names, result|
      let(:names) { names }
      let(:result) { result }
      context "#portorigin_to_pattern(#{names.inspect})" do
        specify { expect(test_class.portorigin_to_pattern(names)).to eq result }
      end
    end
  end

  describe "#pkgname_to_pattern(names)" do
    [
      [ 'apache22-2.2.26', '^apache22-2\\.2\\.26$' ],
      [
        ['php5-5.4.21', 'apache22-2.2.26'],
        '^(php5-5\\.4\\.21|apache22-2\\.2\\.26)$'
      ]
    ].each do |names, result|
      let(:names) { names }
      let(:result) { result }
      context "#pkgname_to_pattern(#{names.inspect})" do
        specify { expect(test_class.pkgname_to_pattern(names)).to eq result }
      end
    end
  end

  describe "#portname_to_pattern(names)" do
    [
      [ 'apache22', "^apache22-#{version_pattern}$" ],
      [ ['php5', 'apache22'], "^(php5|apache22)-#{version_pattern}$" ]
    ].each do |names, result|
      let(:names) { names }
      let(:result) { result }
      context "#portname_to_pattern(#{names.inspect})" do
        specify { expect(test_class.portname_to_pattern(names)).to eq result }
      end
    end
  end

  describe "#mk_search_pattern(key,names)" do
    [
      [:pkgname,  :pkgname_to_pattern ],
      [:portname,   :portname_to_pattern ],
      [:portorigin, :portorigin_to_pattern ],
      [:foobar,     :fullname_to_pattern ]
    ].each do |key, method|
      names = ["name1", "name2"]
      context "#mk_search_pattern(#{key.inspect}, #{names.inspect})" do
        let(:key) { key }
        let(:method) { method }
        let(:names) { names }
        specify "calls ##{method}(#{names}) once" do
          test_class.stubs(method).once.with(names)
          expect { test_class.mk_search_pattern(key,names) }.to_not raise_error
        end
      end
    end
  end

  describe "#portsdir" do
    dir = '/some/dir'
    context "with ENV['PORTSDIR'] unset" do
      context "on FreeBSD" do
        before(:each) do
          Facter.stubs(:value).with(:operatingsystem).returns('FreeBSD')
        end
        specify { expect(test_class.portsdir).to eq '/usr/ports' }
        specify { expect(test_class.portsdir('foo/bar')).to eq '/usr/ports/foo/bar' }
      end
      context "on OpenBSD" do
        before(:each) do
          Facter.stubs(:value).with(:operatingsystem).returns('OpenBSD')
        end
        specify { expect(test_class.portsdir).to eq '/usr/ports' }
        specify { expect(test_class.portsdir('foo/bar')).to eq '/usr/ports/foo/bar' }
      end
      context "on NetBSD" do
        before(:each) do
          Facter.stubs(:value).with(:operatingsystem).returns('NetBSD')
        end
        specify { expect(test_class.portsdir).to eq '/usr/pkgsrc' }
        specify { expect(test_class.portsdir('foo/bar')).to eq '/usr/pkgsrc/foo/bar' }
      end
    end
    context "with ENV['PORTSDIR'] == #{dir.inspect}" do
      let(:dir) { dir }
      before(:each) { ENV.stubs(:[]).with('PORTSDIR').returns(dir) }
      specify { expect(test_class.portsdir).to eq dir }
      specify { expect(test_class.portsdir('foo/bar')).to eq File.join(dir, 'foo/bar') }
    end
  end

  describe "#port_dbdir" do
    dir = '/some/dir'
    context "with ENV['PORT_DBDIR'] unset" do
      specify { expect(test_class.port_dbdir).to eq '/var/db/ports' }
      specify { expect(test_class.port_dbdir('foo/bar')).to eq '/var/db/ports/foo/bar' }
    end
    context "with ENV['PORT_DBDIR'] == #{dir.inspect}" do
      before(:each) { ENV.stubs(:[]).with('PORT_DBDIR').returns(dir) }
      let(:dir) { dir }
      specify { expect(test_class.port_dbdir).to eq dir }
      specify { expect(test_class.port_dbdir('foo/bar')).to eq File.join(dir, 'foo/bar') }
    end
  end

  describe "#portorigin?" do
    [
      'www/apache22',
      'www/apache22-worker-mpm',
      'devel/p5-Locale-gettext',
      'lang/perl5.14',
      'devel/rubygem-json_pure'
    ].each do |str|
      context "#portorigin?(#{str.inspect})" do
        let(:str) { str }
        specify { expect(test_class.portorigin?(str)).to be_truthy }
      end
    end
    [
      nil,
      {},
      [],
      '',
      :test,
      'apache22',
      'apache22-2.2.25',
    ].each do |str|
      context "#portorigin?(#{str.inspect})" do
        let(:str) { str }
        specify { expect { test_class.portorigin?(str) }.to_not raise_error }
        specify { expect(test_class.portorigin?(str)).to be_falsey }
      end
    end
  end

  describe "#pkgname?" do
    [
      '0verkill-0.16_1', # yes, it happens in ports!
      'apache22-2.2.25',
      'apr-1.4.8.1.5.2',
      'autoconf-wrapper-20130530',
      'bison-2.7.1,1',
      'db41-4.1.25_4',
      'f2c-20060810_3',
      'p5-Locale-gettext-1.05_3',
      'p5-Test-Mini-Unit-v1.0.3',
      'bootstrap-openjdk-r316538',
    ].each do |str|
      context "#pkgname?(#{str.inspect})" do
        let(:str) { str }
        specify { expect(test_class.pkgname?(str)).to be_truthy }
      end
    end
    [
      nil,
      {},
      [],
      '',
      'www/apache22',
      'apache22',
    ].each do |str|
      context "#pkgname?(#{str.inspect})" do
        let(:str) { str }
        specify { expect { test_class.pkgname?(str) }.to_not raise_error }
        specify { expect(test_class.pkgname?(str)).to be_falsey }
      end
    end
  end

  describe "#portname?" do
    [
      '0verkill-0.16_1',
      'apache22',
      'autoconf-wrapper',
      'db41-4.1.25_4',
      # they are "well-formed" portnames as well.
      'f2c-20060810_3',
      'p5-Locale-gettext-1.05_3',
      'p5-Test-Mini-Unit-v1.0.3',
      'bootstrap-openjdk-r316538',
      'apache22-2.2.25',
    ].each do |str|
      context "#portname?(#{str.inspect})" do
        let(:str) { str }
        specify { expect(test_class.portname?(str)).to be_truthy }
      end
    end
    [
      nil,
      {},
      [],
      '',
      'www/apache22',
      'bison-2.7.1,1',
    ].each do |str|
      context "#portname?(#{str.inspect})" do
        let(:str) { str }
        specify { expect { test_class.portname?(str) }.to_not raise_error }
        specify { expect(test_class.portname?(str)).to be_falsey }
      end
    end
  end

  describe "#split_pkgname" do
    [
      [ '0verkill-0.16_1', ['0verkill','0.16_1'] ],
      [ 'db41-4.1.25_4', ['db41','4.1.25_4'] ],
      [ 'f2c-20060810_3', ['f2c','20060810_3'] ],
      [ 'p5-Locale-gettext-1.05_3', ['p5-Locale-gettext','1.05_3'] ],
      [ 'p5-Test-Mini-Unit-v1.0.3', ['p5-Test-Mini-Unit','v1.0.3'] ],
      [ 'bootstrap-openjdk-r316538', ['bootstrap-openjdk','r316538'] ],
      [ 'apache22-2.2.25', ['apache22','2.2.25'] ],
      [ 'ruby', ['ruby',nil] ],
    ].each do |pkgname,result|
      context "#split_pkgname(#{pkgname.inspect})" do
        let(:pkgname) { pkgname}
        let(:result) { result}
        specify { expect(test_class.split_pkgname(pkgname)).to eq result}
      end
    end
  end

  describe "#options_files" do
    [
      [
        'ruby', 'lang/ruby19',
        [
          '/var/db/ports/ruby/options',
          '/var/db/ports/ruby/options.local',
          '/var/db/ports/lang_ruby19/options',
          '/var/db/ports/lang_ruby19/options.local'
        ]
      ],
      [
        'figlet', nil,
        [
          '/var/db/ports/figlet/options',
          '/var/db/ports/figlet/options.local',
        ]
      ]
    ].each do |portname,portorigin,result|
      context "#options_files(#{portname.inspect},#{portorigin.inspect})" do
        specify do
          expect(test_class.options_files(portname,portorigin)).to eq result
        end
      end
    end
    context '#options_files("foobar",nil)' do
      specify do
        expect(test_class.options_files('foobar',nil)).to eq [
          '/var/db/ports/foobar/options',
          '/var/db/ports/foobar/options.local'
        ]
      end
    end
    context '#options_files("foobar",nil,false)' do
      specify do
        expect(test_class.options_files('foobar',nil,false)).to eq [
          '/var/db/ports/foobar/options'
        ]
      end
    end
    context '#options_files("foobar","geez/foobar",false)' do
      specify do
        expect(test_class.options_files('foobar','geez/foobar',false)).to eq [
          '/var/db/ports/foobar/options',
          '/var/db/ports/geez_foobar/options'
        ]
      end
    end
    context '#options_files("foobar")' do
      specify do
        expect(test_class.options_files('foobar')).to eq [
          '/var/db/ports/foobar/options',
          '/var/db/ports/foobar/options.local'
        ]
      end
    end
  end

  describe '#bsd_options_mk?' do
    context 'when there is portsdir("Mk/bsd.options.mk")' do
      before(:each) do
        test_class.stubs(:portsdir).once.with('Mk/bsd.options.mk').returns('/opt/ports/Mk/bsd.options.mk')
        File.stubs(:exist?).once.with('/opt/ports/Mk/bsd.options.mk').returns(true)
      end
      specify { expect(test_class.bsd_options_mk?).to be true }
    end
    context 'when there is no portsdir("Mk/bsd.options.mk")' do
      before(:each) do
        test_class.stubs(:portsdir).once.with('Mk/bsd.options.mk').returns('/opt/ports/Mk/bsd.options.mk')
        File.stubs(:exist?).once.with('/opt/ports/Mk/bsd.options.mk').returns(false)
      end
      specify { expect(test_class.bsd_options_mk?).to be false }
    end
  end

  describe '#options_files_portorigin("foo/bar")' do
    context 'when there is Mk/bsd.options.mk' do
      before(:each) do
        test_class.stubs(:bsd_options_mk?).returns(true)
      end
      specify { expect(test_class.options_files_portorigin('foo/bar')).to eq 'foo/bar' }
    end
    context 'when there is no Mk/bsd.options.mk' do
      before(:each) do
        test_class.stubs(:bsd_options_mk?).returns(false)
      end
      specify { expect(test_class.options_files_portorigin('foo/bar')).to be_nil }
    end
  end

  describe '#options_files_default_syntax()' do
    context 'when there is Mk/bsd.options.mk' do
      before(:each) do
        test_class.stubs(:bsd_options_mk?).returns(true)
      end
      specify { expect(test_class.options_files_default_syntax()).to eql :set_unset }
    end
    context 'when there is no Mk/bsd.options.mk' do
      before(:each) do
        test_class.stubs(:bsd_options_mk?).returns(false)
      end
      specify { expect(test_class.options_files_default_syntax()).to eql :with_without }
    end
  end

  describe "#pkgng_active?" do
    pkg = '/a/pkg/path'
    env = { 'TMPDIR' => '/dev/null', 'ASSUME_ALWAYS_YES' => '1',
            'PACKAGESITE' => 'file:///nonexistent' }
    cmd = [pkg,'info','-x',"'pkg(-devel)?$'",'>/dev/null', '2>&1']
    context "when pkg command does not exist" do
      before(:each) do
        FileTest.stubs(:file?).with(pkg).returns(false)
        FileTest.stubs(:executable?).with(pkg).returns(false)
      end
      let(:pkg) { pkg }
      specify { expect(test_class.pkgng_active?({:pkg => pkg})).to eq false }
      specify "should print appropriate debug messages" do
        ::Puppet.expects(:debug).once.with("'pkg' command not found")
        ::Puppet.expects(:debug).once.with("pkgng is inactive on this system")
        test_class.pkgng_active?({:pkg => pkg})
      end
      specify "@pkgng_active should be false after pkgng_active?" do
        test_class.pkgng_active?({:pkg => pkg})
        expect(test_class.instance_variable_get(:@pkgng_active)).to be_falsey
      end
    end
    context "when pkg command exists but pkgng database is not initialized" do
      before(:each) do
        FileTest.stubs(:file?).with(pkg).returns(true)
        FileTest.stubs(:executable?).with(pkg).returns(true)
        Puppet::Util.stubs(:withenv).once.with(env).yields
        Puppet::Util::Execution.stubs(:execpipe).once.with(cmd).raises(Puppet::ExecutionFailure,"")
      end
      let(:pkg) { pkg }
      specify { expect { test_class.pkgng_active?({:pkg => pkg}) }.to_not raise_error }
      specify { expect(test_class.pkgng_active?({:pkg => pkg})).to eq false }
      specify "should print appropriate debug messages" do
        ::Puppet.expects(:debug).once.with("'#{pkg}' command found, checking whether pkgng is active")
        ::Puppet.expects(:debug).once.with("pkgng is inactive on this system")
        test_class.pkgng_active?({:pkg => pkg})
      end
      specify "@pkgng_active should be false after pkgng_active?" do
        test_class.pkgng_active?({:pkg => pkg})
        expect(test_class.instance_variable_get(:@pkgng_active)).to be_falsey
      end
    end
    context "when pkg command exists and pkgng database is initialized" do
      before(:each) do
        FileTest.stubs(:file?).with(pkg).returns(true)
        FileTest.stubs(:executable?).with(pkg).returns(true)
        Puppet::Util.stubs(:withenv).once.with(env).yields
        Puppet::Util::Execution.stubs(:execpipe).once.with(cmd).yields('')
      end
      let(:pkg) { pkg }
      specify { expect { test_class.pkgng_active?({:pkg => pkg}) }.to_not raise_error }
      specify { expect(test_class.pkgng_active?({:pkg => pkg})).to eq true }
      specify "should print appropriate debug messages" do
        ::Puppet.expects(:debug).once.with("'#{pkg}' command found, checking whether pkgng is active")
        ::Puppet.expects(:debug).once.with("pkgng is active on this system")
        test_class.pkgng_active?({:pkg => pkg})
      end
      specify "@pkgng_active should be true after pkgng_active?" do
        test_class.pkgng_active?({:pkg => pkg})
        expect(test_class.instance_variable_get(:@pkgng_active)).to be_truthy
      end
    end
  end
end
