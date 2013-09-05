module Maple::MapleTA

  # HashInitialize allows easily initalizing or hydrating an object from a
  # Hash.
  #
  # In it's simplest form:
  #
  #     class Shape
  #       include HashInitialize
  #       attr_accessor :color, :perimeter, :volume
  #     end
  #
  #     Shape.new(:color => 'red', :perimeter => 54, :volume => 123.5)
  #
  # For more complex scenarios, use "property" to define your object's
  # properties.
  #
  # You can define custom datatype conversions, using the properties:
  #
  #     class Shape
  #       include HashIntialize
  #       property :perimeter, :type => integer
  #     end
  #
  #     myshape = Shape.new(:perimeter => '54')
  #     myshape.perimeter  #=> 54
  #
  # HashInitialize currently supports these datatypes:
  #   * :boolean
  #   * :integer
  #   * :float
  #   * :time_from_s - converts # of seconds since the epoch to a Time
  #   * :time_from_ms - converts # of milliseconds since the epoch to a Time
  #
  #
  # You can translate keys:
  #
  #     class Shape
  #       include HashInitialize
  #       property :perimeter, :from => :totalPerimeter
  #     end
  #
  #     myshape = Shape.new(:totalPerimeter => 54)
  #     myshape.perimeter  #=> 54
  #
  #
  # You can set defaults:
  #
  #     class Shape
  #       include HashInitialize
  #       property :perimeter, :default => 54
  #     end
  #
  #     myshape = Shape.new
  #     myshape.perimeter  #=> 54
  #
  #
  #
  # HashInitialize is similar to the Hashie gem, except that objects do not
  # need to be hashes themselves.
  #
  module HashInitialize

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def property(property_name, options={})

        im = instance_methods.map { |m| m.to_s }

        unless im.include?("#{property_name}=")
          class_eval <<-ACCESSORS
            def #{property_name}
              @#{property_name.to_s}
            end
            def #{property_name}=(value)
              @#{property_name.to_s} = #{converter 'value', options[:type]}
            end
          ACCESSORS
        end

        if options[:from] && !im.include?("#{options[:from]}=")
          class_eval <<-TRANSLATOR
            def #{options[:from]}=(val)
              self.#{property_name} = val
            end
          TRANSLATOR
        end

        if options.has_key?(:default)
          self.defaults[property_name] = options[:default]
        elsif self.defaults.has_key?(property_name)
          self.defaults.delete property_name
        end

      end

      def defaults
        @defaults ||= {}
      end

      def defaults=(val)
        @defaults = val
      end

    private

      def converter(value, type)
        return value if type.nil?

        case type.to_sym
        when :boolean
          "case #{value}\n when nil then nil\n when \"false\" then false\n when \"f\" then false\n else !!#{value}\n end"
        when :integer
          "#{value} && #{value}.to_i"
        when :integer_nilable
          "#{value}.blank? ? nil : #{value}.to_i"
        when :float
          "#{value} && #{value}.to_f"
        when :time_from_s
          "case #{value}\n when nil then nil\n when Time then #{value}\n else Time.at(#{value}.to_i)\n end"
        when :time_from_ms
          "case #{value}\n when nil then nil\n when Time then #{value}\n when #{value}.include?('-') then #{value}.to_time\n else Time.at(#{value}.to_i / 1000, #{value}.to_i % 1000 * 1000)\n end"
        else
          value
        end
      end

    end

    module InstanceMethods

      def initialize(attrs={})
        defaults!
        hydrate(attrs)
      end

      def defaults!
        hydrate(self.class.defaults)
      end

      def hydrate(attrs={})
        attrs.each do |key, val|
          send(:"#{key.to_s}=", val) if respond_to?("#{key.to_s}=")
        end
        self
      end

    end
  end
end
