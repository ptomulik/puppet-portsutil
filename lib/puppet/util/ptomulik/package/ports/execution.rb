require 'puppet/util/ptomulik/package'

begin
  # Puppet > 2.7 has Puppet::Util::Execution.execpipe
  Puppet::Util::Execution.method(:execpipe)
rescue NameError
  # Puppet <= 2.7 has Puppet::Util.execpipe...
  begin
    Puppet::Util.method(:execpipe)
  rescue NameError
    module Puppet::Util
      # .. but it's usually an instance method.
      module_function :execpipe
    end
  end
end

module Puppet::Util::PTomulik::Package::Ports
# Provides `execute_command` and `execpipe` method
module Execution
  def execpipe_method
    return @execpipe_method if @execpipe_method
    begin
      # Puppet > 2.7 has Puppet::Util::Execution.execpipe
      @execpipe_method = Puppet::Util::Execution.method(:execpipe)
    rescue NameError
      # Puppet <= 2.7 has Puppet::Util.execpipe
      @execpipe_method = Puppet::Util.method(:execpipe)
    end
    @execpipe_method
  end
  module_function :execpipe_method
  private :execpipe_method

  # Invoke `Puppet::Util::Execution.execpipe` or `Puppet::Util.execpipe`
  # depending on which one is available first.
  def execpipe(command, *args)
    # Puppet 2.7 would join with '', but we wish ' ' (spaces) between args..
    command_str = command.respond_to?(:join) ? command.join(' ') : command
    execpipe_method.call(command_str, *args) { |pipe| yield pipe }
  end
  module_function :execpipe

  # Execute command via execpipe
  #
  # @param command [Array|String] command to be executed (with args) via
  #   execpipe,
  # @param options [Hash] additional options (not passed to execpipe)
  # @option options :execpipe [Method] handle to a method implementing
  #   execpipe; should have same interface as `Puppet::Util::Execution.execpipe`
  # @option options :failonfail [Boolean] passed as failonfail argument to
  #   `Puppet::Util::Execution.execpipe`
  def execute_command(command, options = {})
    executor = options[:execpipe] || method(:execpipe)
    args = [command]
    args << options[:failonfail] if options.include?(:failonfail)
    executor.call(*args) { |pipe| yield pipe }
  end
  module_function :execute_command
end
end
