module Maple::MapleTA
  module HashInitialize

    def self.included(base)
      base.send :include, InstanceMethods
      #base.send :extend, ClassMethods
    end

    module InstanceMethods

      def initialize(attrs={})
        attrs.each do |key, val|
          send(:"#{key.to_s}=", val) if respond_to?("#{key.to_s}=")
        end
      end

    end
  end
end
