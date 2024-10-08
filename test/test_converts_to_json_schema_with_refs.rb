require 'minitest/autorun'
require 'ostruct'

require_relative '../lib/active_json_schema/converts_to_json_schema_with_refs'

class TestConvertsToJsonSchemaWithRefs < Minitest::Test
  def setup
    # Mock a model class with columns and associations for testing
    @mock_model_class = Minitest::Mock.new
    @mock_model_class.expect :columns_hash, {
      'name' => OpenStruct.new(type: :string, null: false),
      'age' => OpenStruct.new(type: :integer, null: true)
    }
    @mock_model_class.expect :reflect_on_association, nil, ['non_existent_association']
  end

  def test_generate_schema
    schema = ConvertsToJsonSchemaWithRefs.generate(@mock_model_class)
    assert_equal 'object', schema[:type]
    assert_includes schema[:properties].keys, 'name'
    assert_includes schema[:properties].keys, 'age'
  end
end
