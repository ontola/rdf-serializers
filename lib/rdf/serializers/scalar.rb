# frozen_string_literal: true

module RDF
  module Serializers
    module Scalar
      include HextupleSerializer

      attr_accessor :predicate, :image, :datatype

      def initialize(key:, method:, options: {})
        super
        @predicate = options[:predicate]
        @image = options[:image]
        @datatype = options[:datatype]
      end

      def serialize_hex(record, serialization_params)
        return [] unless conditionally_allowed?(record, serialization_params) && predicate.present?

        value = value_from_record(record, method, serialization_params)

        return [] if value.nil?

        if value.is_a?(Array)
          value.map { |arr_item| value_to_hex(iri_from_record(record).to_s, predicate, arr_item, nil, serialization_params) }
        elsif value.is_a?(::RDF::List)
          first = value.statements.first&.subject || RDF.nil
          value.statements.map do |statement|
            value_to_hex(statement.subject.to_s, statement.predicate, statement.object, statement.graph_name, serialization_params)
          end + [
            value_to_hex(iri_from_record(record).to_s, predicate, first, nil, serialization_params)
          ]
        else
          [value_to_hex(iri_from_record(record).to_s, predicate, value, nil, serialization_params)]
        end
      end

      def value_from_record(record, method, serialization_params)
        if method.is_a?(Proc)
          FastJsonapi.call_proc(method, record, serialization_params)
        else
          v = record.public_send(method)
          v.is_a?('ActiveRecord'.safe_constantize&.const_get('Relation') || NilClass) ? v.to_a : v
        end
      end
    end
  end
end

FastJsonapi::Scalar.prepend(RDF::Serializers::Scalar)
