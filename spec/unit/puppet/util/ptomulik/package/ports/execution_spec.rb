#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/util/ptomulik/package/ports/execution'

describe Puppet::Util::PTomulik::Package::Ports::Execution do
  let(:test_execpipe) do
    Class.new do
      def self.execpipe(*args)
        yield :pipe
        return :output
      end
      def self.to_s; 'TestExecpipe'; end
    end
  end

  let(:test_class) do
    Class.new do
      extend Puppet::Util::PTomulik::Package::Ports::Execution
      def self.to_s; 'Pupept::Util::Package::Ports::ExecutionTest'; end
    end
  end

  before :each do
    # Prevent executing commands...
    Puppet::Util.expects(:execpipe).never
    Puppet::Util.stubs(:method).with(:execpipe).raises NameError
    Puppet::Util::Execution.expects(:execpipe).never
    Puppet::Util::Execution.stubs(:method).with(:execpipe).raises NameError
  end

  describe "execute_command" do
    [Puppet::Util::Execution, Puppet::Util].each do |mod|
      context "with #{mod}.execpipe" do
        let(:mod) { mod }
        before :each do
          mod.stubs(:method).with(:execpipe).returns test_execpipe.method(:execpipe)
        end
        specify do
          y = nil
          test_execpipe.expects(:execpipe).once.with(:foo).invoke
          expect(test_class.execute_command(:foo) { |x| y = x }).to be :output
          expect(y).to be :pipe
        end
      end
    end
  end
end
