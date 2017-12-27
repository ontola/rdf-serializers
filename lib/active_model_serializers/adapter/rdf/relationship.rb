# frozen_string_literal: true

module ActiveModelSerializers
  module Adapter
    class RDF
      class Relationship < JsonApi::Relationship
        def triples
          return [] if subject.blank? || predicate.blank? || data.empty?
          data.map do |iri|
            raise "#{iri} is not a RDF::URI but a #{iri.class}" unless iri.is_a?(::RDF::URI)
            [subject, predicate, iri]
          end
        end

        private

        def data
          @data ||=
            if association.collection?
              iri_for_many(association).compact
            else
              [iri_for_one(association)].compact
            end
        end

        def iri_for_many(association)
          collection_serializer = association.lazy_association.serializer
          if collection_serializer.respond_to?(:each)
            collection_serializer.map do |serializer|
              serializer.read_attribute_for_serialization(:iri)
            end
          else
            []
          end
        end

        def iri_for_one(association)
          if belongs_to_id_on_self?(association)
            parent_serializer.read_attribute_for_serialization(:iri)
          else
            serializer = association.lazy_association.serializer
            if (virtual_value = association.virtual_value)
              virtual_value[:id]
            elsif serializer && association.object
              serializer.read_attribute_for_serialization(:iri)
            end
          end
        end

        def predicate
          @predicate ||= association.reflection.options[:predicate]
        end

        def subject
          @subject ||= parent_serializer.read_attribute_for_serialization(:iri)
        end
      end
    end
  end
end
