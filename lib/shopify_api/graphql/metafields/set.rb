# frozen_string_literal: true

require_relative "request"

module ShopifyAPI
  module GraphQL
    module Metafields
      class Set < Request      # :nodoc: all
        # Shopify limit per call
        MAX = 25

        MUTATION =<<-GQL
          mutation metafieldsSet($metafields: [MetafieldsSetInput!]!) {
            metafieldsSet(metafields: $metafields) {
              metafields { %s }
              #{Metafields::USER_ERRORS}
            }
          }
        GQL

        DEFAULT_FIELDS = %w[id namespace key value].freeze

        def execute(metafields, options = nil)
          metafields = wrap_array(metafields)
          raise ArgumentError, "metafields required" if metafields.size == 0
          raise ArgumentError, "#{metafields.size} metafields provided: Shopify allows a maximum of #{MAX}. Use the Batch::Set class instead" if metafields.size > MAX

          options = (options || {}).dup
          fields = options.delete(:fields) || DEFAULT_FIELDS
          super(
            sprintf(MUTATION, field_string(fields)),
            { :metafields => metafields },
            options
          )
        end
      end
    end
  end
end
