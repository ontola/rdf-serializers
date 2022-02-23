# frozen_string_literal: true

module RDF
  module Serializers
    module Relationship
      include HextupleSerializer

      attr_accessor :predicate, :image, :association, :sequence

      def include_relationship?(record, serialization_params, included = false)
        return false if lazy_load_data && !included

        super(record, serialization_params)
      end

      def serialize_hex(record, nested_includes, serialization_params, resources_to_include)
        included = !nested_includes.nil?
        return [] unless include_relationship?(record, serialization_params, included) && (predicate.present? || included)

        objects = objects_for_relationship(record, serialization_params)
        objects_to_include(objects, record, included).each do |object|
          add_to_include_list(resources_to_include, object, nested_includes, @serializer)
        end

        return [] if predicate.blank?

        iris = objects.map(&method(:iri_from_record))

        sequence ? relationship_sequence(record, iris, serialization_params) : relationship_statements(record, iris, serialization_params)
      end

      private

      def add_to_include_list(resources_to_include, object, nested_includes, serializer_class)
        key = iri_from_record(object).to_s
        resources_to_include[key] ||= {
          includes: {},
          resource: object,
          serializer_class: serializer_class
        }
        resources_to_include[key][:includes].merge!(nested_includes) if nested_includes
      end

      def objects_to_include(objects, record, included)
        included ? objects : objects.select { |object| part_of_document(record, object) }
      end

      def relationship_sequence(record, iris, serialization_params)
        return [] if iris.blank?

        sequence = RDF::Node.new

        [
          value_to_hex(iri_from_record(record).to_s, resolve_predicate(0), sequence, nil, serialization_params),
          value_to_hex(sequence, RDF.type, RDF.Seq, nil, serialization_params)
        ] + iris.map.with_index do |iri, index|
          value_to_hex(sequence, RDF["_#{index}"], iri, nil, serialization_params)
        end
      end

      def relationship_statements(record, iris, serialization_params)
        iris.map.with_index do |related_iri, index|
          value_to_hex(
            iri_from_record(record).to_s,
            resolve_predicate(index),
            related_iri,
            nil,
            serialization_params
          )
        end
      end

      def resolve_predicate(index)
        return predicate unless predicate.respond_to?(:call)

        predicate.call(self, index)
      end

      def objects_for_relationship(record, params = {})
        initialize_static_serializer unless @initialized_static_serializer

        associated_object = fetch_associated_object(record, params)
        return [] unless associated_object

        associated_object.respond_to?(:map) ? associated_object.compact : [associated_object]
      end

      def part_of_document(record, object)
        return false if object.try(:uri?)
        object_iri = iri_from_record(object)

        object.iri.node? ||
          iri_from_record(record).to_s.split('#').first == object_iri.to_s.split('#').first
      end
    end
  end
end

FastJsonapi::Relationship.prepend(RDF::Serializers::Relationship)
