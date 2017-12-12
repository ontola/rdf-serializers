# frozen_string_literal: true

module ActiveModelSerializers
  module Adapter
    class RDF < Base
      extend ActiveSupport::Autoload
      autoload :Relationship

      delegate :object, to: :serializer
      delegate :dump, to: :graph

      def initialize(serializer, options = {})
        super
        @include_directive = JSONAPI::IncludeDirective.new(options[:include], allow_wildcard: true)
        @fieldset = options[:fieldset] || ActiveModel::Serializer::Fieldset.new(options.delete(:fields))
        @resource_identifiers = Set.new
      end

      protected

      attr_reader :fieldset

      private

      def add_attribute(data, iri, value)
        predicate = data.options[:predicate]
        return unless predicate
        value = value.respond_to?(:each) ? value : [value]
        value.compact.map { |v| add_triple(iri, predicate, v) }
      end

      def add_triple(subject, predicate, object)
        obj =
          case object
          when ::RDF::Resource, ::RDF::Literal
            object
          when ActiveSupport::TimeWithZone
            ::RDF::Literal(object.to_datetime)
          else
            ::RDF::Literal(object)
          end
        @graph << [::RDF::URI(subject), ::RDF::URI(predicate), obj]
      end

      def attributes_for(serializer, fields)
        serializer.class._attributes_data.map do |key, data|
          next if data.excluded?(serializer)
          next unless fields.nil? || fields.include?(key)
          add_attribute(data, serializer.read_attribute_for_serialization(:iri), serializer.attributes[key])
        end
      end

      def graph
        return @graph if @graph.present?
        @graph = ::RDF::Graph.new

        serializers.each { |serializer| process_resource(serializer, @include_directive) }
        serializers.each { |serializer| process_relationships(serializer, @include_directive) }
        instance_options[:meta]&.each { |meta| add_triple(*meta) }

        @graph
      end

      def process_relationship(serializer, include_slice)
        if serializer.respond_to?(:each)
          serializer.each { |s| process_relationship(s, include_slice) }
          return
        end
        return unless serializer&.object
        return unless process_resource(serializer, include_slice)
        process_relationships(serializer, include_slice)
      end

      def process_relationships(serializer, include_slice)
        serializer.associations(include_slice).each do |association|
          process_relationship(association.lazy_association.serializer, include_slice[association.key])
        end
      end

      def process_resource(serializer, include_slice = {})
        return unless serializer.respond_to?(:iri) || serializer.object.respond_to?(:iri)
        return false unless @resource_identifiers.add?(serializer.read_attribute_for_serialization(:iri))
        resource_object_for(serializer, include_slice)
        true
      end

      def relationships_for(serializer, requested_associations, include_slice)
        include_directive = JSONAPI::IncludeDirective.new(
          requested_associations,
          allow_wildcard: true
        )
        serializer.associations(include_directive, include_slice).each do |association|
          Relationship.new(serializer, instance_options, association).triples.each do |triple|
            @graph << triple
          end
        end
      end

      def resource_object_for(serializer, include_slice = {})
        type = type_for(serializer, instance_options).to_s
        serializer.fetch(self) do
          break nil if serializer.read_attribute_for_serialization(:iri).nil?
          requested_fields = fieldset&.fields_for(type)
          attributes_for(serializer, requested_fields)
        end
        requested_associations = fieldset.fields_for(type) || '*'
        relationships_for(serializer, requested_associations, include_slice)
      end

      def serializers
        serializer.respond_to?(:each) ? serializer : [serializer]
      end

      def type_for(serializer, instance_options)
        JsonApi::ResourceIdentifier.new(serializer, instance_options).as_json[:type]
      end
    end
  end
end
