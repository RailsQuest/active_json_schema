# ActiveJsonSchema

ActiveJsonSchema is a Ruby gem that extends ActiveRecord models to generate JSON Schema representations. It provides an easy way to create JSON Schema definitions for your ActiveRecord models, including support for associations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_json_schema"
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install active_json_schema
```

## Usage

### Basic Usage

To use ActiveJsonSchema in your ActiveRecord models, include the `ActiveJsonSchema::ToJsonSchema` module:

```ruby
class User < ActiveRecord::Base
  include ActiveJsonSchema::ToJsonSchema

  has_many :posts
end

class Post < ActiveRecord::Base
  include ActiveJsonSchema::ToJsonSchema

  belongs_to :user
end
```

Now you can generate JSON Schema for your models:

```ruby
user_schema = User.to_json_schema
puts user_schema
```

This will output a JSON Schema representation of the User model, including all its attributes.

### Customizing Schema Generation

You can customize the schema generation by passing options to the `to_json_schema` method:

```ruby
# Generate schema for specific attributes only
user_schema = User.to_json_schema(only: %w[name email])

# Include associations in the schema
user_schema = User.to_json_schema(associations: %w[posts])

# Customize association options
user_schema = User.to_json_schema(associations: { posts: { only: %w[title content] } })

# Allow additional properties
user_schema = User.to_json_schema(additional_properties: true)
```

### Working with Associations

ActiveJsonSchema supports generating schemas for associated models:

```ruby
class User < ActiveRecord::Base
  include ActiveJsonSchema::ToJsonSchema

  has_many :posts
end

user_schema = User.to_json_schema(associations: %w[posts])
```

This will include a `posts_attributes` property in the User schema, referencing the Post schema definition.

### Overriding Default Behavior

You can override the default `to_json_schema` method in your models for more control:

```ruby
class Post < ActiveRecord::Base
  include ActiveJsonSchema::ToJsonSchema

  def self.to_json_schema(only: %w[title content], **)
    super
  end
end
```

This example will always include only the 'title' and 'content' attributes in the Post schema unless specified otherwise.

## Examples

Here are some more examples to illustrate the usage:

```ruby
# Generate schema for User model with all attributes
User.to_json_schema

# Generate schema for User model with specific attributes and associations
User.to_json_schema(only: %w[name email], associations: %w[posts])

# Generate schema for Post model with customized association
Post.to_json_schema(associations: { user: { only: %w[name] } })

# Generate schema with nested associations
User.to_json_schema(associations: { posts: { associations: %w[comments] } })
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pingortle/active_json_schema. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
