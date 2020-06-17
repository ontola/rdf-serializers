# frozen_string_literal: true

module RDF
  module Serializers
    module Relationship
      include HextupleSerializer

      attr_accessor :predicate, :image, :association, :sequence

      def serialize_hex(record, included, serialization_params)
        return [] unless include_relationship?(record, serialization_params, included) && predicate.present?

        iris = iris_from_record_and_relationship(record, serialization_params)

        sequence ? relationship_sequence(record, iris, serialization_params) : relationship_statements(record, iris, serialization_params)
      end

      def relationship_sequence(record, iris, serialization_params)
        sequence = RDF::Node.new

        [
          value_to_hex(iri_from_record(record).to_s, predicate, sequence, nil, serialization_params),
          value_to_hex(sequence, RDF.type, RDF.Seq, nil, serialization_params)
        ] + iris.map.with_index do |iri, index|
          value_to_hex(sequence, RDF["_#{index}"], iri, nil, serialization_params)
        end
      end

      def relationship_statements(record, iris, serialization_params)
        iris.map do |related_iri|
          value_to_hex(
            iri_from_record(record).to_s,
            predicate,
            related_iri,
            nil,
            serialization_params
          )
        end
      end

      def include_relationship?(record, serialization_params, included = false)
        return false if lazy_load_data && !included

        super(record, serialization_params)
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
