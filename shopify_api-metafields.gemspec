# frozen_string_literal: true

require "strings/case"
require_relative "lib/shopify_api/metafields/version"

Gem::Specification.new do |spec|
  spec.name = "shopify_api-metafields"
  spec.version = ShopifyAPI::Metafields::VERSION
  spec.authors       = ["Skye Shaw"]
  spec.email         = ["skye.shaw@gmail.com"]

  spec.summary = "User-friendly metafield wrapper around Shopify's GraphQL Admin API with built-in retry, batching, and error handling"

  spec.homepage = "https://github.com/ScreenStaring/shopify_api-metafields"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"
  spec.metadata = {
    "bug_tracker_uri"   => "https://github.com/ScreenStaring/shopify_api-metafields/issues",
    "changelog_uri"     => "https://github.com/ScreenStaring/shopify_api-metafields/blob/master/Changes",
    "documentation_uri" => "https://rubydoc.info/gems/shopify_api-metafields",
    "source_code_uri"   => "https://github.com/ScreenStaring/shopify_api-metafields",
    "homepage_uri" => spec.homepage
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "shopify_api-graphql-request"
  spec.add_dependency "strings-case"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "tiny_gid"
end
