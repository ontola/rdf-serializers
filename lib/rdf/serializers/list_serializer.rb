# frozen_string_literal: true

module RDF
  module Serializers
    class ListSerializer
      include RDF::Serializers::ObjectSerializer

      def hextuples_for_collection
        @resource.map do |resource|
          RDF::Serializers.serializer_for(resource).record_hextuples(resource, nil, @rdf_includes, @params)
        end.flatten(1)
      end

      class << self
        def validate_includes!(_includes); end
      end
    end
  end
end
