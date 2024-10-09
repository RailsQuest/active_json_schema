# frozen_string_literal: true

class ConvertsToJsonSchemaWithRefs
  class UnsupportedAssociationType < StandardError; end

  def self.generate(model_class, only: nil, associations: {}, additional_properties: false)
    new(model_class, only: only, associations: associations, additional_properties: additional_properties).generate
  end

  def initialize(model_class, only: nil, associations: [], additional_properties: false)
    @model_class = model_class
    @only = only
    @associations = associations.is_a?(Array) ? associations.to_h { |a| [a, {}] } : associations
    @additional_properties = additional_properties
    @definitions = {}
  end

  def generate
    schema = {
      type: "object",
      properties: properties_for(@model_class, @only, @associations),
      required: required_properties(@model_class, @only),
      additionalProperties: @additional_properties
    }
    schema[:definitions] = @definitions unless @definitions.empty?
    schema
  end

  private

  def properties_for(model_class, only, associations)
    properties = {}

    model_class.columns_hash.each do |column_name, column_info|
      next unless only.nil? || only.include?(column_name)

      properties[column_name] = column_to_json_property(column_info)
    end

    associations.each do |association_name, options|
      association = model_class.reflect_on_association(association_name)
      next unless association

      definition_name = association.klass.name.underscore
      if options.empty?
        klass = association.klass
        unless klass.ancestors.include?(ActiveJsonSchema::ToJsonSchema)
          raise UnsupportedAssociationType.new("Please include ActiveJsonSchema::ToJsonSchema in #{klass} or specify association options.")
        end

        nested_schema = klass.to_json_schema
        @definitions.merge!(nested_schema[:definitions] || {})
        @definitions[definition_name] ||= nested_schema.except(:definitions)
      else
        @definitions[definition_name] ||= generate_definition(association.klass, options)
      end

      property_name = "#{association_name}_attributes"
      properties[property_name] = association_to_json_property(association, definition_name)
    end

    properties
  end

  def generate_definition(model_class, options)
    only = options[:only]
    nested_associations = options[:associations] || {}

    {
      type: "object",
      properties: properties_for(model_class, only, nested_associations),
      required: required_properties(model_class, only)
    }
  end

  def required_properties(model_class, only)
    model_class.columns_hash.select do |column_name, column_info|
      (only.nil? || only.include?(column_name)) && !column_info.null
    end.keys
  end

  def column_to_json_property(column_info)
    property = {type: sql_type_to_json_type(column_info.type)}

    case column_info.type
    when :string, :text
      property[:maxLength] = column_info.limit if column_info.limit
    when :integer, :bigint
      property[:minimum] = 0 if column_info.sql_type.include?("unsigned")
    when :decimal
      property[:multipleOf] = 10**-column_info.scale if column_info.scale
    end

    property
  end

  def association_to_json_property(association, definition_name)
    case association.macro
    when :has_many, :has_and_belongs_to_many
      {
        type: "array",
        items: {"$ref": "#/definitions/#{definition_name}"}
      }
    when :belongs_to, :has_one
      {"$ref": "#/definitions/#{definition_name}"}
    else
      raise "Unsupported association type: #{association.macro}"
    end
  end

  def sql_type_to_json_type(sql_type)
    case sql_type
    when :string, :text
      "string"
    when :integer, :bigint
      "integer"
    when :float, :decimal
      "number"
    when :boolean
      "boolean"
    when :date, :datetime, :time
      "string"
    else
      "string"
    end
  end
end
