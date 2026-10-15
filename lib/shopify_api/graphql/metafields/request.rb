# frozen_string_literal: true

require "shopify_api/graphql/request"

module ShopifyAPI
  module GraphQL
    module Metafields
      class Request < ShopifyAPI::GraphQL::Request
        protected

        def wrap_array(object)
          (object.is_a?(Array) ? object : [object]).compact
        end

        def field_string(fields)
          return fields unless fields.respond_to?(:map)
          # TODO: check for breakage across the set of accepted fields
          fields.map { |f| Strings::Case.camelcase(f.to_s) }.join("\n")
        end
      end
    end
  end
end
