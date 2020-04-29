# frozen_string_literal: true

module RDF
  module Serializers
    class NilSerializer
      include RDF::Serializers::ObjectSerializer

      class << self
        def validate_includes!(_includes); end
      end
    end
  end
end
