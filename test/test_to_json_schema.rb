require 'minitest/autorun'
require 'active_record'
require 'sqlite3'

require_relative '../lib/active_json_schema/to_json_schema'
require_relative '../lib/active_json_schema/converts_to_json_schema_with_refs'

class TestToJsonSchema < Minitest::Test
  # Define a simple ActiveRecord model
  class User < ActiveRecord::Base
    include ActiveJsonSchema::ToJsonSchema
  end

  def setup
    # Set up an in-memory SQLite database
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

    # Create a simple table for testing
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name, null: false
        t.integer :age
        t.timestamps
      end
    end
  end

  def test_to_json_schema
    schema = User.to_json_schema
    assert_equal 'object', schema[:type]
    assert_includes schema[:properties].keys, 'name'
    assert_includes schema[:properties].keys, 'age'
  end
end
