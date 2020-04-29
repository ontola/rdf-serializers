# frozen_string_literal: true

module RDF
  module Serializers
    def self.configure
      yield @config ||= RDF::Serializers::Configuration.new
    end

    def self.config
      @config
    end

    class Configuration
      include ActiveSupport::Configurable
      config_accessor :always_include_named_graphs
      config_accessor :default_graph
      config_accessor :serializer_lookup_chain
      config_accessor :serializer_lookup_enabled
    end

    configure do |config|
      config.always_include_named_graphs = true

      config.serializer_lookup_enabled = true

      # For configuring how serializers are found.
      # This should be an array of procs.
      #
      # The priority of the output is that the first item
      # in the evaluated result array will take precedence
      # over other possible serializer paths.
      #
      # i.e.: First match wins.
      #
      # @example output
      # => [
      #   "CustomNamespace::ResourceSerializer",
      #   "ParentSerializer::ResourceSerializer",
      #   "ResourceNamespace::ResourceSerializer" ,
      #   "ResourceSerializer"]
      #
      # If CustomNamespace::ResourceSerializer exists, it will be used
      # for serialization
      config.serializer_lookup_chain = RDF::Serializers::LookupChain::DEFAULT.dup
    end
  end
end
