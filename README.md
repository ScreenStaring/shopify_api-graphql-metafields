# ShopifyAPI::GraphQL::Metafields

User-friendly metafield wrapper around Shopify's GraphQL Admin API with built-in retry, batching, and error handling.

## Installation

```bash
bundle add shopify_api-graphql-metafields
```

If bundler is not being used to manage dependencies:

```bash
gem install shopify_api-graphql-metafields
```

## Usage

`ShopifyAPI::GraphQL::Metafields` supports CRUD operations on Metafields and Metafield Definitions, and supports setting metafields in bulk.

### Metafields

#### Upsert Metafields

You can upsert a single metafield or multiple metafields:

```rb
require "shopify_api/graphql/metafields"

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

mf = ShopifyAPI::GraphQL::Metafields.new(shop, token)

begin
  results = mf.set(metafields)
  results.each do |result|
    # result is a Hash with underscored Symbol keys
    p result.slice(:id, :value)
  end
rescue ShopifyAPI::GraphQL::Metafields::Error => e
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

mf = ShopifyAPI::GraphQL::Metafields.new(shop, token)

begin
  results = mf.delete(metafields)
  results.each do |result|
    # result is a Hash
    p result.slice(:key, :namespace)
  end
rescue ShopifyAPI::GraphQL::Metafields::Error => e
  p e
end
```

To override the fields returned see [Field Selection](#field-selection).

### Field Selection

Use the `:fields` option to select what fields are returned. This accepts an `Array` of field names:

```rb
mf = ShopifyAPI::GraphQL::Metafields.new(shop, token)
mf.set(metafield, :fields => %w[compare_digest legacy_resource_id description])
```

Or a String containing literal GraphQL fields:

```rb
mf.set(metafield, :fields => "legacyResourceId constraints { key }")
```

### Setting Metafields in Bulk

```rb
require "shopify_api/graphql/metafields"

set = ShopifyAPI::GraphQL::Metafields::Batch::Set.new(shop, token)
set << metafield1
set << metafield2
# ...
set << metafield100

begin
  result = set.flush!
rescue ShopifyAPI::GraphQL::Metafields::Batch::Error => e
  p "Bulk set failed: #{e}"
  if e.results.any?
    p "We did have _some_ success:"
    pp e.results
  end

  if e.errors.any?
    p "We encountered some errors:"
    pp e.errors
  end

  if e.user_errors.any?
    p "We encountered some user errors:"
    pp e.user_errors
  end
end
```

Note that this _does not_ use the Shopify Bulk API. If you want to use the Bulk API for metafields or other operations
see [`ShopifyAPI::GraphQL::Bulk`](https://github.com/ScreenStaring/shopify_api-graphql-bulk).

Once `#flush!` is called worker threads (if needed) will be spawned and metafields will be set 25 at a time, per Shopify's `Mutations.metafieldsSet` call limit.
You can control the number of threads via the `:worker_count` option:

```rb
set = ShopifyAPI::GraphQL::Metafields::Bulk.new(shop, token, :worker_count => 8)
```

Workers are spawned based on the batch size. If you have 50 metafields only 2 workers will be spawned. If you have 25 or less only no workers are spawned.

The default number of workers is 4.

The return value is an `Array` of results like one gets with `Metafield#set`. The indices will align with the input metafields' indices.
A `nil` value means that position errored.

### Deleting Metafields in Bulk

TODO!

If you need this you can use Shopify's Bulk API via [`ShopifyAPI::GraphQL::Bulk`](https://github.com/ScreenStaring/shopify_api-graphql-bulk).

### Metafield Definitions

```rb
require "shopify_api/graphql/metafields"

dfn = ShopifyAPI::GraphQL::Metafields::Definition.new(shop, token)
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

```rb
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
