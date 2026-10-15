require "spec_helper"

RSpec.describe ShopifyAPI::GraphQL::Metafields do
  METAFIELD_TEST_KEY = "testsuite"

  describe "#set" do
    it "creates a new metafield" do
      product_id = SKU_MAPPING.fetch("TEST-UPDATE")
      key = "created-#{Time.now.to_i}"

      result = client.set(
        :owner_id => gid::Product(product_id),
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => key,
        :type => "number_integer",
        :value => "123"
      )

      expect(result).to match([
        :id => %r{\Agid://shopify/Metafield/\d+\z},
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => key,
        :value => "123"
      ])

      value = metafield(key, product_id)
      expect(value).to eq "123"
    end

    it "updates an existing metafield" do
      expected = Time.now.to_i.to_s
      product_id = SKU_MAPPING.fetch("TEST-UPDATE")

      result = client.set(
        :owner_id => gid::Product(product_id),
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => METAFIELD_TEST_KEY,
        :type => "number_integer",
        :value => expected
      )

      expect(result).to match([
        :id => %r{\Agid://shopify/Metafield/\d+\z},
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => METAFIELD_TEST_KEY,
        :value => expected
      ])

      value = metafield(METAFIELD_TEST_KEY, product_id)
      expect(value).to eq expected
    end

    it "upserts multiple metafields" do
      update_id = SKU_MAPPING.fetch("TEST-UPDATE")
      create_id = SKU_MAPPING.fetch("TEST-ADD")

      expected = Time.now.to_i.to_s

      key = "created-#{Time.now.to_i}"

      result = client.set([
        {
          :owner_id => gid::Product(update_id),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY,
          :type => "number_integer",
          :value => expected
        },
        {
          :owner_id => gid::Product(create_id),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => key,
          :type => "single_line_text_field",
          :value => expected
        }
      ])

      expect(result).to match([
        {
          :id => %r{\Agid://shopify/Metafield/\d+\z},
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY,
          :value => expected
        },
        {
          :id => %r{\Agid://shopify/Metafield/\d+\z},
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => key,
          :value => expected
        }
      ])

      value = metafield(METAFIELD_TEST_KEY, update_id)
      expect(value).to eq expected

      value = metafield(key, create_id)
      expect(value).to eq expected
    end

    it "raises an error when more than 25 metafields are given" do
      product_id = SKU_MAPPING.fetch("TEST-UPDATE")

      metafields = 26.times.map do |i|
        {
          :owner_id => gid::Product(product_id),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => "batch-#{i}",
          :type => "number_integer",
          :value => i.to_s
        }
      end

      expect {
        client.set(metafields)
      }.to raise_error(ArgumentError, "26 metafields provided: Shopify allows a maximum of 25. Use the Batch::Set class instead")

      result = nil
      expect {
        result = client.set(metafields[0..-2])
      }.to_not raise_error

      expect(result.size).to eq 25
    end

    describe "user-defined fields" do
      before do
        product_id = SKU_MAPPING.fetch("TEST-UPDATE")

        @metafield = {
          :owner_id => gid::Product(product_id),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY,
          :type => "number_integer",
          :value => "999"
        }
      end

      it "returns the selected fields given a literal GraphQL String" do
        result = client.set(@metafield, :fields => "ownerType namespace")

        expect(result).to eq([
          :owner_type => "PRODUCT",
          :namespace => METAFIELD_TEST_NAMESPACE
        ])
      end

      it "returns the selected fields given an Array of snake_case Symbols" do
        result = client.set(@metafield, :fields => [:owner_type, :namespace])

        expect(result).to eq([
          :owner_type => "PRODUCT",
          :namespace => METAFIELD_TEST_NAMESPACE
        ])
      end

      it "returns the selected fields given an Array of Strings" do
        result = client.set(@metafield, :fields => %w[owner_type namespace])

        expect(result).to eq([
          :owner_type => "PRODUCT",
          :namespace => METAFIELD_TEST_NAMESPACE
        ])
      end
    end
  end

  describe "#delete" do
    it "deletes a metafield" do
      product_id = SKU_MAPPING.fetch("TEST-DELETE1")

      result = client.delete(
        :owner_id => gid::Product(product_id),
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => METAFIELD_TEST_KEY
      )

      expect(result).to match([
        :owner_id => gid::Product(product_id),
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => METAFIELD_TEST_KEY
      ])

      value = metafield(METAFIELD_TEST_KEY, product_id)
      expect(value).to be_nil
    end

    it "deletes multiple metafields" do
      product_id1 = SKU_MAPPING.fetch("TEST-DELETE2")
      product_id2 = SKU_MAPPING.fetch("TEST-DELETE3")

      result = client.delete([
        {
          :owner_id => gid::Product(product_id1),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY
        },
        {
          :owner_id => gid::Product(product_id2),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY
        }
      ])

      expect(result).to match([
        {
          :owner_id => gid::Product(product_id1),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY
        },
        {
          :owner_id => gid::Product(product_id2),
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY
        }
      ])

      value = metafield(METAFIELD_TEST_KEY, product_id1)
      expect(value).to be_nil

      value = metafield(METAFIELD_TEST_KEY, product_id2)
      expect(value).to be_nil
    end

    describe "user-defined fields" do
      before do
        @metafield = {
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => METAFIELD_TEST_KEY
        }
      end

      it "returns the selected fields given a literal GraphQL String" do
        product_id = SKU_MAPPING.fetch("TEST-DELETE-FIELDS1")
        @metafield[:owner_id] = gid::Product(product_id)

        result = client.delete(@metafield, :fields => "key namespace")

        expect(result).to eq([
          :key => METAFIELD_TEST_KEY,
          :namespace => METAFIELD_TEST_NAMESPACE
        ])
      end

      it "returns the selected fields given an Array of snake_case Symbols" do
        product_id = SKU_MAPPING.fetch("TEST-DELETE-FIELDS2")
        @metafield[:owner_id] = gid::Product(product_id)

        result = client.delete(@metafield, :fields => [:key, :namespace])

        expect(result).to eq([
          :key => METAFIELD_TEST_KEY,
          :namespace => METAFIELD_TEST_NAMESPACE
        ])
      end

      it "returns the selected fields given an Array of Strings" do
        product_id = SKU_MAPPING.fetch("TEST-DELETE-FIELDS3")
        @metafield[:owner_id] = gid::Product(product_id)

        result = client.delete(@metafield, :fields => %w[key namespace])

        expect(result).to eq([
          :key => METAFIELD_TEST_KEY,
          :namespace => METAFIELD_TEST_NAMESPACE
        ])
      end
    end
  end
end
