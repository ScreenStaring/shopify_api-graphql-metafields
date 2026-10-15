# frozen_string_literal: true

require "csv"
require "dotenv"
require "json"
require "open3"
require "shopify_api/metafields"
require "gid"

Dotenv.load
gid.app = "shopify"

SKU_MAPPING = {}
METAFIELD_TEST_NAMESPACE = "shopifyapi-metafields"

module Util
  def sdt(command, *options)
    command = sprintf(
      "sdt %s --shop %s --access-token %s %s",
      command,
      ENV.fetch("SHOPIFY_DOMAIN"),
      ENV.fetch("SHOPIFY_ADMIN_TOKEN"),
      options.join(" ")
    )

    warn command if ENV["DEBUG"] == "1"

    stdout, stderr, status = Open3.capture3(command)
    # If only some rows fail we'll have no stderr
    raise "sdt command failed: #{stderr || stdout}" unless status.success?

    stdout
  end

  def definitions(resource)
    lines = sdt("metafield definitions ls", "-j", resource)
    return [] if lines.strip.empty?

    lines.each_line.map { |json| JSON.parse(json) }
  end

  def metafield(key, id)
    json = sdt("metafield product", "-j -k", key, id)
    return if json.strip.empty?

    JSON.parse(json).fetch("value")
  end

  def client(options = {})
    described_class.new(ENV.fetch("SHOPIFY_DOMAIN"), ENV.fetch("SHOPIFY_ADMIN_TOKEN"), options)
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include Util
  config.before(:suite) do
    extend Util

    path = File.join(__dir__, "fixtures/products.csv")
    csv = CSV.read(path, :headers => true, :skip_blanks => true)

    result = sdt("products import -j -i handle", path)
    JSON.parse(result).map.with_index do |row, i|
      SKU_MAPPING[csv[i]["Variant SKU"]] = row["id"]
    end
  end
end
