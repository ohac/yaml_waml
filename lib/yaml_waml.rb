# -*- coding: utf-8 -*-
require "yaml"

class String
  def is_binary_data?
    false
  end
end

module YamlWaml
  def decode(orig_yamled)
    yamled_str = case orig_yamled
                 when String then orig_yamled
                 when StringIO then orig_yamled.string
                 else return orig_yamled
                 end

    yamled_str.gsub!(/(?:\\x([0-9a-fA-F]{2})){1,100}/) {|s| [ s.split(/\\x/).join ].pack('H*') }
    return yamled_str
  end
  module_function :decode

  class FakeIO
    attr_accessor :real_io

    def initialize real_io
      @real_io = real_io
    end

    def class
      IO
    end

    def write(str)
      @real_io.write YamlWaml.decode(str)
    end

    alias << write

    def method_missing *args, &block
      @real_io.__send__ *args, &block
    end

  end

end

ObjectSpace.each_object(Class) do |klass|
  klass.class_eval do
    if method_defined?(:to_yaml) && !method_defined?(:to_yaml_with_decode)
      def to_yaml_with_decode(io = StringIO.new )
        require 'pp'
        # pp caller(0)
        if io && io.kind_of?(IO)
          fake_io = YamlWaml::FakeIO.new(io)
          io = fake_io
        end
        result_io = to_yaml_without_decode(io)
        case result_io
        when StringIO
          return ::YamlWaml.decode(result_io.string)
        else
          return result_io
        end
      end
      alias_method :to_yaml_without_decode, :to_yaml
      alias_method :to_yaml, :to_yaml_with_decode
    end
  end
end

