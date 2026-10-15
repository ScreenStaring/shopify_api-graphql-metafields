# frozen_string_literal: true

require_relative "delete"
require_relative "set"

module ShopifyAPI
  module GraphQL
    module Metafields
      class Metafield           # :nodoc: all
        def initialize(shop, token, options = nil)
          @delete = Metafields::Delete.new(shop, token, options)
          @set = Metafields::Set.new(shop, token, options)
        end

        def set(metafields, options = nil)
          @set.execute(metafields, options).dig(:data, :metafields_set, :metafields)
        end

        def delete(metafields, options = nil)
          @delete.execute(metafields, options).dig(:data, :metafields_delete, :deleted_metafields)
        end
      end
    end
  end
end
