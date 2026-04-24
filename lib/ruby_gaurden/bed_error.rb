# frozen_string_literal: true

require 'ruby_gaurden'

module RubyGaurden
  class BedError < Error
    def self.[](class_name)
      bed_class_name = :"Bed#{class_name}"

      if const_defined?(bed_class_name) && (klass = const_get(bed_class_name)) < self
        klass
      else
        const_set(bed_class_name, Class.new(self))
      end
    end
  end
end
