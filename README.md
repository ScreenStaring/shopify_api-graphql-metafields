# ShopifyAPI::Metafields

User-friendly metafield wrapper around Shopify's GraphQL Admin API with built-in retry, batching, and error handling,

## Installation

```bash
bundle add shopify_api-metafields
```

If bundler is not being used to manage dependencies:

```bash
gem install shopify_api-metafields
```

## Usage

`ShopifyAPI::Metafields` support CRUD operations on Metafields and Metafield Definitions, and supports
setting and creating metafields in bulk.

### Metafields

#### Upsert Metafields

You can upsert a single metafield or multiple metafields:

```rb
require "shopify_api/metafields"

metafields = [
  {
    :owner_id => "gid://shopify/Product/123",
    :namespace => "something",
    :key => "foo",
    # Not required if there's a metafield definition
    :type => "number_integer",
    :value => "123"
  },
  {
    :owner_id => "gid://shopify/Shop/123",
    :namespace => "whatever",
    :key => "bar",
    :type => "json",
    :value => JSON.dump(:a => 123, :b => "bee")
  }
]

mf = ShopifyAPI::Metafields::Metafield.new(shop, token)

begin
  results = mf.set(metafields)
  results.each do |result|
    # result is a Hash with underscored Symbol keys
    p result.slice(:id, :value)
  end
rescue ShopifyAPI::Metafields::Error => e
  p e
end
```

To override the fields returned see [Field Selection](#field-selection).

#### Delete Metafields

```rb
metafields = [
  {
    :owner_id => "gid://shopify/Product/123",
    :namespace => "something",
    :key => "foo"
  },
  {
    :owner_id => "gid://shopify/Shop/123",
    :namespace => "whatever",
    :key => "bar"
  }
]

mf = ShopifyAPI::Metafields::Metafield.new(shop, token)

begin
  results = mf.delete(metafields)
  results.each do |result|
    # result is a Hash
    p result.slice(:key, :namespace)
  end
rescue ShopifyAPI::Metafields::Error => e
  p e
end
```

To override the fields returned see [Field Selection](#field-selection).

### Field Selection

Use the `:fields` option to select what fields are returned. This accepts an `Array` of field names:

```rb
mf = ShopifyAPI::Metafields::Metafield.new(shop, token)
mf.set(metafield, :fields => %w[compare_digest legacy_resource_id description])
```

Or a String containing literal GraphQL fields:

```rb
mf.set(metafield, :fields => "legacyResourceId constraints { key }")
```

### Deleting Metafields in Bulk

TODO!

If you need this you can use Shopify's Bulk API via [`ShopifyAPI::GraphQL::Bulk`](https://github.com/ScreenStaring/shopify_api-graphql-bulk).

### Metafield Definitions

```rb
require "shopify_api/metafields"

dfn = ShopifyAPI::Metafields::Definition.new(shop, token)
result = dfn.create(
  :name => "My amaaaazing definition",
  :namespace => "sshaw",
  :key => "ingredients",
  :description => "A product's ingredients",
  :type => "multi_line_text_field",
  :owner_type => "PRODUCT"
)

id = result.dig(:created_definition, :id)

result = dfn.update(
  :namespace => "sshaw",
  :key => "ingredients",
  :owner_type => "PRODUCT",
  :description => "A products SUPER SECRET ingredients"
)

# More CRUD operations...
```

#### Field Selection

Similar to other metafield operation you can specify the returned fields:

```
id = { :namespace => "sshaw", :key => "ingredients", :owner_type => "PRODUCT" }
dfn.get(id, :fields => %w[id pinned_position])

# Or, specify a String:
dfn.get(id, :fields => "id pinnedPosition constraints { key value }")
```

## Development

[Shopify Development Tools](https://github.com/ScreenStaring/shopify-dev-tools/) is used to import the text fixtures and retrieve values. The `sdt` executable must be in your path.

A Shopify test store is required. `cp .env.template .env` and fill-in the values.

## See Also

- [Shopify Dev Tools](https://github.com/ScreenStaring/shopify-dev-tools/) - Command-line program to assist with the development and/or maintenance of Shopify apps and stores
- [`ShopifyAPI::GraphQL::Tiny`](https://github.com/ScreenStaring/shopify_api-graphql-tiny/) - Lightweight, no-nonsense, Shopify GraphQL Admin API client with built-in pagination and retry
- [`ShopifyAPI::GraphQL::Request`](https://github.com/ScreenStaring/shopify_api-graphql-request) - A higher-level wrapper around this class with improved exception handling and `:snake_case` hash key conversion
- [`TinyGID`](https://github.com/sshaw/tiny_gid/) - Build Global ID (`gid://`) URI strings from scalar values

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

Made by [ScreenStaring](https://screenstaring.com)
