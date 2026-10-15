# frozen_string_literal: true

require_relative "metafields/version"

module ShopifyAPI
  module Metafields
    Error = Class.new(StandardError)

    USER_ERRORS =<<-GQL
      userErrors {
        field
        message
        code
      }
    GQL
  end
end

require_relative "metafields/metafield"
require_relative "metafields/batch"
require_relative "metafields/definition"
