require "spec_helper"

# Stand-in for ShopifyAPI::GraphQL::Metafields::Set. It records the calls made by each worker
# thread so worker count, grouping, and result ordering can be asserted without
# making any requests to Shopify.
class SetRecorder
  attr_reader :calls

  def initialize(response = nil)
    @calls = []
    @mutex = Mutex.new
    @response = response
  end

  def execute(metafields)
    @mutex.synchronize do
      @calls << [Thread.current.name, metafields.map { |metafield| metafield[:key] }]
    end

    return @response.call(metafields) if @response

    { :data => { :metafields_set => { :metafields => metafields } } }
  end
end

RSpec.describe ShopifyAPI::GraphQL::Metafields::Batch::Set do
  def batch_metafields(keys, owner_id = 1, value = "1")
    keys.map do |key|
      {
        :owner_id => gid::Product(owner_id),
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => key,
        :type => "number_integer",
        :value => value
      }
    end
  end

  def recorder_calls(recorder)
    recorder.calls.map { |call| [call[0], call[1].first, call[1].size] }.sort
  end

  describe ".new" do
    it "raises an error when worker_count is less than 1" do
      expect { client(:worker_count => 0) }.to raise_error(ArgumentError, "worker_count must be greater than 0")
    end
  end

  describe "#flush!" do
    it "sets more than 25 metafields" do
      product_id = SKU_MAPPING.fetch("TEST-UPDATE")
      keys = 30.times.map { |i| "batch-integration-#{i}" }

      set = client
      set << batch_metafields(keys, product_id)
      result = set.flush!

      expect(result.size).to eq 30
      # Last metafield of the first batch, first of the second, and the last overall
      expect(metafield("batch-integration-24", product_id)).to eq "1"
      expect(metafield("batch-integration-25", product_id)).to eq "1"
      expect(metafield("batch-integration-29", product_id)).to eq "1"
    end

    it "raises an error when Shopify rejects a batch" do
      product_id = SKU_MAPPING.fetch("TEST-UPDATE")
      good_keys = 25.times.map { |i| "batch-error-#{i}" }
      bad_keys = 25.times.map { |i| "batch-error-#{i + 25}" }

      set = client
      set << batch_metafields(good_keys, product_id)
      set << batch_metafields(bad_keys, 0)

      # Shopify returns one user error per metafield in the rejected batch
      user_errors = 25.times.map do |i|
        { "field" => ["metafields", i.to_s, "ownerId"], "message" => "Owner does not exist.", "code" => "INVALID_VALUE" }
      end
      batch_message = 25.times.map { |i| "metafields.#{i}.ownerId: Owner does not exist." }.join("\n")

      expect { set.flush! }.to raise_error(
        ShopifyAPI::GraphQL::Metafields::Batch::Error,
        "Failed to set all metafields: 1 error(s): #{batch_message}"
      ) do |error|
        expect(error.user_errors).to eq user_errors

        expect(error.errors.size).to eq 1
        expect(error.errors[0]).to be_a ShopifyAPI::GraphQL::Request::UserError
        expect(error.errors[0].message).to eq batch_message

        # The first batch succeeded, the second failed so its positions hold no result
        expect(error.results.size).to eq 50
        expect(error.results[0..24].map { |metafield| metafield[:key] }).to eq good_keys
        expect(error.results[25..49]).to eq Array.new(25)
      end

      expect(metafield("batch-error-0", product_id)).to eq "1"
    end

    it "spawns 4 workers to upload metafields in groups of 25" do
      recorder = SetRecorder.new
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      keys = 100.times.map { |i| "batch-#{i}" }
      set = client
      set << batch_metafields(keys)

      result = set.flush!

      expect(result.map { |metafield| metafield[:key] }).to eq keys
      expect(recorder_calls(recorder)).to eq [
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000000", "batch-0", 25],
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000001", "batch-25", 25],
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000002", "batch-50", 25],
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000003", "batch-75", 25]
      ]
    end

    it "spawns a single worker when there are fewer batches than workers" do
      recorder = SetRecorder.new
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      keys = 25.times.map { |i| "batch-#{i}" }
      set = client
      set << batch_metafields(keys)

      result = set.flush!

      expect(result.map { |metafield| metafield[:key] }).to eq keys
      expect(recorder_calls(recorder)).to eq [
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000000", "batch-0", 25]
      ]
    end

    it "uses the worker_count option" do
      recorder = SetRecorder.new
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      keys = 100.times.map { |i| "batch-#{i}" }
      set = client(:worker_count => 2)
      set << batch_metafields(keys)

      result = set.flush!

      expect(result.map { |metafield| metafield[:key] }).to eq keys
      expect(recorder_calls(recorder)).to eq [
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000000", "batch-0", 25],
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000000", "batch-25", 25],
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000001", "batch-50", 25],
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000001", "batch-75", 25]
      ]
    end

    it "returns results in the order the metafields were added" do
      recorder = SetRecorder.new
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      keys = 300.times.map { |i| "batch-#{i}" }
      set = client(:worker_count => 12)
      set << batch_metafields(keys)

      result = set.flush!

      expect(result.map { |metafield| metafield[:key] }).to eq keys
      expect(recorder.calls.map { |call| call[0] }.uniq.size).to eq 12
    end

    it "returns false when no metafields have been added" do
      recorder = SetRecorder.new
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      set = client

      expect(set.flush!).to be false
      expect(recorder.calls).to eq []
    end

    it "clears the metafields after flushing" do
      recorder = SetRecorder.new
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      set = client
      set << batch_metafields(%w[batch-0 batch-1])

      expect(set.flush!.map { |metafield| metafield[:key] }).to eq %w[batch-0 batch-1]
      expect(set.flush!).to be false
    end

    it "adds metafields given as separate arguments or Arrays" do
      recorder = SetRecorder.new
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      set = client
      set << batch_metafields(%w[batch-0])
      set << batch_metafields(%w[batch-1]) + batch_metafields(%w[batch-2])

      result = set.flush!

      expect(recorder_calls(recorder)).to eq [
        ["ShopifyAPI::GraphQL::Metafields::Batch::Set-batch-000000", "batch-0", 3]
      ]
      expect(result.map { |metafield| metafield[:key] }).to eq %w[batch-0 batch-1 batch-2]
    end

    it "raises an error containing the user errors Shopify returns" do
      user_errors = [
        { "field" => %w[metafields 0 value], "message" => "Invalid value", "code" => "INVALID_VALUE" }
      ]

      recorder = SetRecorder.new(lambda { |metafields|
        raise ShopifyAPI::GraphQL::Request::UserError, user_errors if metafields.first[:key] == "batch-25"

        { :data => { :metafields_set => { :metafields => metafields } } }
      })
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      keys = 50.times.map { |i| "batch-#{i}" }
      set = client
      set << batch_metafields(keys)

      error = nil
      begin
        set.flush!
      rescue ShopifyAPI::GraphQL::Metafields::Batch::Error => e
        error = e
      end

      expect(error).to have_attributes(
        :message => "Failed to set all metafields: 1 error(s): metafields.0.value: Invalid value",
        :user_errors => user_errors
      )
      expect(error.results.size).to eq 50
      expect(error.results[0..24].map { |metafield| metafield[:key] }).to eq keys[0..24]
      # The batch holding keys 25..49 failed, so those positions hold no result
      expect(error.results[25..49]).to eq Array.new(25)
    end

    it "raises an error when a worker raises an error" do
      recorder = SetRecorder.new(lambda { |metafields|
        raise ShopifyAPI::GraphQL::Request::Error, "Connection reset" if metafields.first[:key] == "batch-25"

        { :data => { :metafields_set => { :metafields => metafields } } }
      })
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      keys = 50.times.map { |i| "batch-#{i}" }
      set = client
      set << batch_metafields(keys)

      error = nil
      begin
        set.flush!
      rescue ShopifyAPI::GraphQL::Metafields::Batch::Error => e
        error = e
      end

      expect(error).to have_attributes(
        :message => "Failed to set all metafields: 1 error(s): Connection reset",
        :user_errors => []
      )
      expect(error.results.size).to eq 50
      expect(error.results[0..24].map { |metafield| metafield[:key] }).to eq keys[0..24]
      # The batch holding keys 25..49 failed, so those positions hold no result
      expect(error.results[25..49]).to eq Array.new(25)
    end

    it "keeps setting a worker's remaining batches after one fails" do
      recorder = SetRecorder.new(lambda { |metafields|
        raise ShopifyAPI::GraphQL::Request::Error, "Connection reset" if metafields.first[:key] == "batch-25"

        { :data => { :metafields_set => { :metafields => metafields } } }
      })
      allow(ShopifyAPI::GraphQL::Metafields::Set).to receive(:new).and_return(recorder)

      keys = 75.times.map { |i| "batch-#{i}" }
      set = client(:worker_count => 1)
      set << batch_metafields(keys)

      error = nil
      begin
        set.flush!
      rescue ShopifyAPI::GraphQL::Metafields::Batch::Error => e
        error = e
      end

      expect(recorder.calls.size).to eq 3
      expect(error.results.size).to eq 75
      expect(error.results[0..24].map { |metafield| metafield[:key] }).to eq keys[0..24]
      # The batch holding keys 25..49 failed, so those positions hold no result
      expect(error.results[25..49]).to eq Array.new(25)
      expect(error.results[50..74].map { |metafield| metafield[:key] }).to eq keys[50..74]
    end
  end
end
