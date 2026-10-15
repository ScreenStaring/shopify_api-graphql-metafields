require "spec_helper"

RSpec.describe ShopifyAPI::Metafields::Definition do
  before do
    @key = "testsuite-%d" % Process.clock_gettime(Process::CLOCK_REALTIME, :nanosecond)
    @definition = {
      :name => "Name",
      :namespace => METAFIELD_TEST_NAMESPACE,
      :key => @key,
      :description => "Description",
      :type => "multi_line_text_field",
      :owner_type => "PRODUCT"
    }
  end

  describe "#create" do
    it "creates a definition" do
      result = client.create(@definition)

      expect(result[:created_definition]).to match(
        :id => %r{\Agid://shopify/MetafieldDefinition/\d+\z},
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => @key,
        :name => "Name",
        :description => "Description",
        :owner_type => "PRODUCT",
        :type => { :name => "multi_line_text_field" }
      )

      id = gid.to_sc(result[:created_definition][:id])
      shopify = definitions("product").find { |d| d["id"] == id }
      expect(shopify).to eq(
        "id" => id,
        "namespace" => METAFIELD_TEST_NAMESPACE,
        "key" => @key,
        "name" => "Name",
        "description" => "Description",
        "type" => "multi_line_text_field",
        "ownerType" => "PRODUCT"
      )
    end

    it "creates a definition and returns the specified fields" do
      result = client.create(@definition, :fields => %i[key owner_type])
      expect(result[:created_definition]).to match(
        :key => @key,
        :owner_type => "PRODUCT"
      )

      shopify = definitions("product").find { |d| d["key"] == @key && d["namespace"] == METAFIELD_TEST_NAMESPACE }
      expect(shopify).to_not be_nil
    end
  end

  describe "#delete" do
    before do
      @result = client.create(@definition)
    end

    it "deletes a definition by ID" do
      id = @result[:created_definition][:id]
      client.delete(id)

      shopify = definitions("product").find { |d| d["id"] == gid.to_sc(id) }
      expect(shopify).to be_nil
    end

    it "deletes a definition by user-defined identifier" do
      client.delete(:key => @key, :namespace => METAFIELD_TEST_NAMESPACE, :owner_type => "PRODUCT")

      id = gid.to_sc(@result[:created_definition][:id])
      shopify = definitions("product").find { |d| d["id"] == id }
      expect(shopify).to be_nil
    end
  end

  describe "#get" do
    before do
      @id = client.create(@definition).dig(:created_definition, :id)
    end

    it "retrieves the definition by id" do
      result = client.get(@id)
      expect(result).to eq(
        :id => @id,
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => @key,
        :name => "Name",
        :description => "Description",
        :type => { :name => "multi_line_text_field" },
        :owner_type => "PRODUCT"
      )
    end

    it "retrieves the definition by identifier Hash" do
      result = client.get(:key => @key, :namespace => METAFIELD_TEST_NAMESPACE, :owner_type => "PRODUCT")
      expect(result).to eq(
        :id => @id,
        :namespace => METAFIELD_TEST_NAMESPACE,
        :key => @key,
        :name => "Name",
        :description => "Description",
        :type => { :name => "multi_line_text_field" },
        :owner_type => "PRODUCT"
      )
    end

    it "raise an error is the definition cannot be found" do
      expect {
        client.get(gid::MetafieldDefinition(1))
      }.to raise_error(ShopifyAPI::GraphQL::Request::NotFoundError, /No record found for metafieldDefinition/)
    end
  end

  describe "#update" do
    it "updates the definition" do
      name = client.create(@definition).dig(:created_definition, :name)
      expect(name).to eq "Name"

      updated = @definition.merge(:name => "Foo")
      updated.delete(:type)

      name = client.update(updated).dig(:updated_definition, :name)
      expect(name).to eq "Foo"
    end

    it "raise an error if the definition cannot be found" do
      expect {
        client.update(
          :namespace => METAFIELD_TEST_NAMESPACE,
          :key => "foohoowoo-123",
          :owner_type => "SHOP"
        )
      }.to raise_error(ShopifyAPI::GraphQL::Request::UserError, /Definition not found/)
    end
  end
end
