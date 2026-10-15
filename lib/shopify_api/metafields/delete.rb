# frozen_string_literal: true

require_relative "request"

module ShopifyAPI
  module Metafields
    class Delete < Request      # :nodoc: all
      MAX = 250

      MUTATION =<<-GQL
        mutation metafieldsDelete($metafields: [MetafieldIdentifierInput!]!) {
          metafieldsDelete(metafields: $metafields) {
            deletedMetafields { %s }
            userErrors { field message }
          }
        }
      GQL

      DEFAULT_FIELDS = %w[key namespace owner_id].freeze

      def execute(metafields, options = nil)
        metafields = wrap_array(metafields)
        raise ArgumentError, "metafields required" if metafields.size == 0
        raise ArgumentError, "#{metafields.size} metafields provided: Shopify allows a maximum of #{MAX}" if metafields.size > MAX

        fields = options ? options[:fields] : DEFAULT_FIELDS
        super(
          sprintf(MUTATION, field_string(fields)),
          :metafields => metafields
        )
      end
    end
  end
end
