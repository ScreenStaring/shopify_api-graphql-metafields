# frozen_string_literal: true

require_relative "batch/set"

module ShopifyAPI
  module GraphQL
    module Metafields
      module Batch
        class Error < ShopifyAPI::GraphQL::Metafields::Error
          # Array containing results of any successfully executed set calls
          attr_reader :results

          # Array containing errors, if any
          attr_reader :errors

          # Array containing user errors, if any
          attr_reader :user_errors

          def initialize(message, results = nil, errors = nil, user_errors = nil)
            super message

            @results = results || []
            @errors = errors || []
            @user_errors = user_errors || []
          end
        end
      end
    end
  end
end
