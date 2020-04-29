# frozen_string_literal: true

module RDF
  module Serializers
    module Relationship
      include HextupleSerializer

      attr_accessor :predicate, :image, :association

      def serialize_hex(record, included, serialization_params)
        return [] unless include_relationship?(record, serialization_params) && predicate.present?

        statements = []

        unless lazy_load_data && !included
          iris_from_record_and_relationship(record, serialization_params).each do |related_iri|
            statements << value_to_hex(
              iri_from_record(record).to_s,
              predicate,
              related_iri
            )
          end
        end

        statements.compact
      end

      def iris_from_record_and_relationship(record, params = {})
        initialize_static_serializer unless @initialized_static_serializer

        associated_object = fetch_associated_object(record, params)
        return [] unless associated_object

        if associated_object.respond_to? :map
          return associated_object.compact.map do |object|
            iri_from_record(object)
          end
        end

        [iri_from_record(associated_object)]
      end
    end
  end
end

FastJsonapi::Relationship.prepend(RDF::Serializers::Relationship)
