require "yaml"

class String
  def is_binary_data?
    false
  end
end

module YamlWaml
  module Util
    def convert_chars! target
      splitter = /\\x/
      target.gsub!(/(?:\\x(\w{2})){0,100}/) do |s|
        s.split(splitter).map {|i| (i.nil? || i == "" ) ? nil : i.to_i(16) }.compact.pack('C*').gsub("\0", '')
      end
    end

    module_function :convert_chars!
  end
end

ObjectSpace.each_object(Class) do |klass|
  klass.class_eval do
    if method_defined?(:to_yaml) && !method_defined?(:to_yaml_with_decode)
      def to_yaml_with_decode(*args)
        result = to_yaml_without_decode(*args)
        if result.kind_of? String
          ::YamlWaml::Util.convert_chars!(result)
        elsif result.kind_of? StringIO
          str = result.string
          str = ::YamlWaml::Util.convert_chars!(str)

          result.rewind
          result.write str
          result
        else
          result
        end
      end
      alias_method :to_yaml_without_decode, :to_yaml
      alias_method :to_yaml, :to_yaml_with_decode
    end
  end
end

