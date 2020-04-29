# frozen_string_literal: true

module RDF
  module Serializers
    module HextupleSerializer
      def iri_from_record(record)
        return record if record.try(:uri?)

        raise FastJsonapi::MandatoryField, 'record has no iri' unless record.respond_to?(:iri)

        record.iri
      end

      def normalized_object(object)
        case object
        when ::RDF::Term
          object
        when ActiveSupport::TimeWithZone
          ::RDF::Literal(object.to_datetime)
        else
          ::RDF::Literal(object)
        end
      end

      def object_value(obj)
        if obj.is_a?(::RDF::URI)
          obj.value
        elsif obj.is_a?(::RDF::Node)
          obj.to_s
        else
          obj.value.to_s
        end
      end

      def object_datatype(obj)
        if obj.is_a?(::RDF::URI)
          'http://www.w3.org/1999/02/22-rdf-syntax-ns#namedNode'
        elsif obj.is_a?(::RDF::Node)
          'http://www.w3.org/1999/02/22-rdf-syntax-ns#blankNode'
        elsif obj.try(:datatype?)
          obj.datatype
        else
          lit = RDF::Literal(obj)
          lit.datatype.to_s
        end
      end

      def value_to_hex(iri, predicate, object, graph = nil)
        return if object.nil?

        obj = normalized_object(object)

        [
          iri,
          predicate.to_s,
          object_value(obj),
          object_datatype(obj),
          obj.try(:language) || '',
          (graph || ::RDF::Serializers.config.default_graph)&.value
        ]
      end
    end
  end
end
