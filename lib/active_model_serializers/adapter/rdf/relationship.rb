# frozen_string_literal: true

module ActiveModelSerializers
  module Adapter
    class RDF
      class Relationship < JsonApi::Relationship
        def statements
          return [] if no_data?

          data.map do |object|
            raise "#{object} is not a RDF::Resource but a #{object.class}" unless object.is_a?(::RDF::Resource)

            ::RDF::Statement.new(subject, predicate, object, graph_name: graph_name)
          end
        end

        private

        def data
          @data ||=
            if association.collection?
              objects_for_many(association).compact
            else
              [object_for_one(association)].compact
            end
        end

        def graph_name
          association.reflection.options[:graph] || ::RDF::Serializers.config.default_graph
        end

        def no_data?
          subject.blank? || predicate.blank? || data.empty?
        end

        def objects_for_many(association)
          collection_serializer = association.lazy_association.serializer
          if collection_serializer.respond_to?(:each)
            collection_serializer.map do |serializer|
              serializer.read_attribute_for_serialization(:rdf_subject)
            end
          else
            []
          end
        end

        def object_for_one(association)
          if belongs_to_id_on_self?(association)
            parent_serializer.read_attribute_for_serialization(:rdf_subject)
          else
            serializer = association.lazy_association.serializer
            if (virtual_value = association.virtual_value)
              virtual_value[:id]
            elsif serializer && association.object
              serializer.read_attribute_for_serialization(:rdf_subject)
            end
          end
        end

        def predicate
          @predicate ||= association.reflection.options[:predicate]
        end

        def subject
          @subject ||= parent_serializer.read_attribute_for_serialization(:rdf_subject)
        end
      end
    end
  end
end
