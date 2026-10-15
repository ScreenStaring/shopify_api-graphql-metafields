# frozen_string_literal: true

require "shopify_api/graphql/request"

module ShopifyAPI
  module Metafields
    module Batch
      # TODO: Similar operation for delete
      class Set < ShopifyAPI::GraphQL::Request
        DEFAULT_UPLOAD_GROUPS = 4

        def initialize(shop, token, options = nil)
          super(shop, token)

          @shop = shop
          @token = token

          @metafields = []
          @options = options || {}

          raise ArgumentError, "worker_count must be greater than 0" if @options[:worker_count] && @options[:worker_count].to_i < 1
        end

        def <<(*metafields)
          metafields.flatten!

          # TODO: autoflush?
          @metafields.concat(metafields)

          nil
        end

        def flush!
          return false unless @metafields.any?

          batches = @metafields.each_slice(Metafields::Set::MAX)
          # Round so we don't end up with a fractional (or 0) slice size
          groups = (batches.size / worker_count.to_f).round
          groups = 1 if groups < 1

          workers = batches.each_slice(groups).with_index.map { |batch, i| spawn_worker(batch, i) }
          workers.each(&:join)

          collect_results(workers)
        ensure
          @metafields.clear
        end

        private

        def worker_count
          @options[:worker_count] || DEFAULT_UPLOAD_GROUPS
        end

        def collect_results(workers)
          results = []
          errors = []
          user_errors = []

          # Name contains its position within the batch, zero-padded so sorting by name
          # is the same as sorting by position.
          # The goal is for the success results' indices to align with input values'
          workers.sort_by(&:name).each do |worker|
            worker_results, worker_errors = worker.value

            results.concat(worker_results)
            errors.concat(worker_errors)

            worker_errors.each do |error|
              user_errors.concat(error.errors) if error.is_a?(ShopifyAPI::GraphQL::Request::UserError)
            end
          end

          if errors.any?
            message = errors.map(&:message).join(", ")
            raise Error.new("Failed to set all metafields: #{errors.size} error(s): #{message}", results, errors, user_errors)
          end

          if user_errors.any?
            # This error can be a bit misleading since any array positions shown will likely not be correct
            message = user_errors.map(&:message).join(", ")
            raise Error.new("Failed to set all metafields: #{user_errors.size} user error(s): #{message}", results, errors, user_errors)
          end

          results
        end

        def spawn_worker(batches, id)
          Thread.new do
            Thread.current.name = sprintf("%s-batch-%06d", self.class, id)

            errors = []
            # We treat the result like the metafieldSet mutation where each position holds the input position's result.
            # If there was no result the position is nil. This will be put back together across all threads and returned to
            # the caller as if it was a single metafieldSet call
            results = Array.new(batches.sum(&:size))

            set = Metafields::Set.new(@shop, @token)

            offset = 0

            batches.each do |batch|
              begin
                results[offset, batch.size] = set.execute(batch).dig(:data, :metafields_set, :metafields)
              rescue => e
                errors << e
              end

              offset += batch.size
            end

            [results, errors]
          end
        end
      end
    end
  end
end
