# frozen_string_literal: true

require_relative "active_json_schema/version"

module ActiveJsonSchema
  class Error < StandardError; end
  require_relative "active_json_schema/converts_to_json_schema_with_refs"
  require_relative "active_json_schema/to_json_schema"
end
