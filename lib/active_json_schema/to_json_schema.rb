# frozen_string_literal: true

module ActiveJsonSchema
  module ToJsonSchema
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def to_json_schema(only: nil, associations: {}, additional_properties: false)
        ConvertsToJsonSchemaWithRefs.generate(self, only: only, associations: associations, additional_properties: additional_properties)
      end
    end
  end
end
