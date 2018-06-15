require 'capybara/dsl'

module QA
  module Factory
    class Product
      include Capybara::DSL

      attr_reader :location

      Attribute = Struct.new(:name, :block)

      def initialize(location)
        @location = location
      end

      def visit!
        visit @location
      end

      def self.populate!(factory, location)
        new(location).tap do |product|
          factory.class.attributes.each_value do |attribute|
            product.instance_exec(factory, attribute.block) do |factory, block|
              value = block.call(factory)
              product.define_singleton_method(attribute.name) { value }
            end
          end
        end
      end
    end
  end
end
