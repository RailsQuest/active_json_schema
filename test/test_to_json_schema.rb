require "minitest/autorun"
require "active_record"
require "sqlite3"

require_relative "../lib/active_json_schema/to_json_schema"
require_relative "../lib/active_json_schema/converts_to_json_schema_with_refs"

class TestToJsonSchema < Minitest::Test
  # Define a simple ActiveRecord model
  class Post < ActiveRecord::Base
    include ActiveJsonSchema::ToJsonSchema

    def self.to_json_schema(only: %w[title], **)
      super
    end
  end

  class PostWithoutJsonSchema < ActiveRecord::Base
    self.table_name = "posts"
  end

  class User < ActiveRecord::Base
    include ActiveJsonSchema::ToJsonSchema

    has_many :posts
    has_many :post_without_json_schemas
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

  def test_to_json_schema
    schema = User.to_json_schema
    assert_equal "object", schema[:type]
    assert_includes schema[:properties].keys, "name"
    assert_includes schema[:properties].keys, "age"
  end

  def test_generate_schema_with_convenience_method
    schema = User.to_json_schema(only: %w[name age], associations: %w[posts])

    assert_equal "object", schema[:type]
    assert_includes schema[:properties].keys, "name"
    assert_includes schema[:properties].keys, "age"
    assert_includes schema[:properties].keys, "posts_attributes"
    assert_includes schema.dig(:properties, "posts_attributes", :items, :$ref), "#/definitions/test_to_json_schema/post"
    assert_equal schema.dig(:definitions, "test_to_json_schema/post", :properties).keys, %w[title]
  end

  def test_generate_schema_with_convenience_method_associating_to_excluded_different_model
    assert_raises(ConvertsToJsonSchemaWithRefs::UnsupportedAssociationType) do
      User.to_json_schema(only: %w[name age], associations: %w[post_without_json_schemas])
    end
  end
end
