require "minitest/autorun"
require "pretty_diffs"
require "active_record"
require "sqlite3"

require_relative "../lib/active_json_schema/converts_to_json_schema_with_refs"

class TestConvertsToJsonSchemaWithRefs < Minitest::Test
  include PrettyDiffs
  # Define a simple ActiveRecord model
  class Post < ActiveRecord::Base; end

  class User < ActiveRecord::Base
    has_many :posts
  end

  def setup
    # Set up an in-memory SQLite database
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

    # Create a simple table for testing
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.string :name, null: false
        t.integer :age
        t.timestamps
      end

      create_table :posts, force: true do |t|
        t.string :title, null: false
        t.integer :user_id
        t.timestamps
      end
    end
  end

  def test_generate_schema
    schema = ConvertsToJsonSchemaWithRefs.generate(User)
    assert_equal "object", schema[:type]
    assert_includes schema[:properties].keys, "name"
    assert_includes schema[:properties].keys, "age"
  end

  def test_comprehensive_schema_generation
    expected_schema = {
      type: "object",
      properties: {
        "id" => {type: "integer"},
        "name" => {type: "string"},
        "age" => {type: "integer"},
        "created_at" => {type: "string"},
        "updated_at" => {type: "string"}
      },
      required: %w[id name created_at updated_at],
      additionalProperties: false
    }

    schema = ConvertsToJsonSchemaWithRefs.generate(User)
    assert_equal expected_schema, schema
  end

  def test_comprehensive_schema_generation_with_associations
    expected = {
      type: "object",
      properties: {
        "id" => {type: "integer"},
        "name" => {type: "string"},
        "age" => {type: "integer"},
        "created_at" => {type: "string"},
        "updated_at" => {type: "string"},
        "posts_attributes" => {type: "array",
                               items: {:$ref => "#/definitions/test_converts_to_json_schema_with_refs/post"}}
      },
      required: %w[id name created_at updated_at],
      additionalProperties: false,
      definitions: {
        "test_converts_to_json_schema_with_refs/post" => {
          type: "object",
          properties: {},
          required: []
        }
      }
    }

    actual = ConvertsToJsonSchemaWithRefs.generate(User, associations: {posts: {only: %i[id title]}})

    assert_equal expected, actual
  end
end
