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
    end

    configure do |config|
      config.always_include_named_graphs = true
    end
  end
end
