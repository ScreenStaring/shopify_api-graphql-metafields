# frozen_string_literal: true

require "shopify_api/graphql/tiny"
require "shopify_api/graphql/request"

require_relative "metafields/version"

module ShopifyAPI
  module GraphQL
    module Metafields
      Error = Class.new(StandardError)

      WRAPPED_ERRORS = [
        ShopifyAPI::GraphQL::Tiny::Error,
        ShopifyAPI::GraphQL::Request::Error
      ].freeze

      USER_ERRORS =<<-GQL
        userErrors {
          field
          message
          code
        }
      GQL

      def self.new(shop, token, options = nil)
        Metafield.new(shop, token, options)
      end
    end
  end
end

require_relative "metafields/metafield"
require_relative "metafields/batch"
require_relative "metafields/definition"
