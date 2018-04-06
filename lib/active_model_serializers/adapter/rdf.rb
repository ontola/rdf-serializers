# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module ActiveModelSerializers
  module Adapter
    class RDF < Base
      extend ActiveSupport::Autoload
      autoload :Relationship

      delegate :object, to: :serializer

      def initialize(serializer, options = {})
        super
        @include_directive = JSONAPI::IncludeDirective.new(options[:include], allow_wildcard: true)
        @fieldset = options[:fieldset] || ActiveModel::Serializer::Fieldset.new(options.delete(:fields))
        @resource_identifiers = Set.new
      end

      def dump(*args, **options)
        if include_named_graphs?(*args)
          repository.dump(*args, options)
        else
          repository.project_graph(nil).dump(*args, options)
        end
      end

      def triples(*args, **options)
        if include_named_graphs?(*args)
          repository.triples(*args, options)
        else
          repository.project_graph(nil).triples(*args, options)
        end
      end

      protected

      attr_reader :fieldset

      private

      def add_attribute(subject, predicate, value)
        return unless predicate
        value = value.respond_to?(:each) ? value : [value]
        value.compact.map { |v| add_triple(subject, predicate, v) }
      end

      def add_triple(subject, predicate, object, graph = nil)
        obj =
          case object
          when ::RDF::Term
            object
          when ActiveSupport::TimeWithZone
            ::RDF::Literal(object.to_datetime)
          else
            ::RDF::Literal(object)
          end
        @repository << ::RDF::Statement.new(subject, ::RDF::URI(predicate), obj, graph_name: graph)
      end

      def attributes_for(serializer, fields)
        serializer.attributes(fields).each do |key, value|
          add_attribute(
            serializer.read_attribute_for_serialization(:rdf_subject),
            serializer.class._attributes_data[key].try(:options).try(:[], :predicate),
            value
          )
        end
      end

      def custom_triples_for(serializer)
        serializer.class.try(:_triples)&.map do |key|
          serializer.read_attribute_for_serialization(key).each do |triple|
            @repository << triple
          end
        end
      end

      def repository
        return @repository if @repository.present?
        @repository = ::RDF::Repository.new

        serializers.each { |serializer| process_resource(serializer, @include_directive) }
        serializers.each { |serializer| process_relationships(serializer, @include_directive) }
        instance_options[:meta]&.each { |meta| add_triple(*meta) }

        @repository
      end

      def include_named_graphs?(*args)
        ::RDF::Serializers.config.always_include_named_graphs ||
          ::RDF::Writer.for(*args.presence || :nquads).instance_methods.include?(:write_quad)
      end

      def process_relationship(serializer, include_slice)
        return serializer.each { |s| process_relationship(s, include_slice) } if serializer.respond_to?(:each)
        return unless serializer&.object && process_resource(serializer, include_slice)
        process_relationships(serializer, include_slice)
      end

      def process_relationships(serializer, include_slice)
        return unless serializer.respond_to?(:associations)
        serializer.associations(include_slice).each do |association|
          process_relationship(association.lazy_association.serializer, include_slice[association.key])
        end
      end

      def process_resource(serializer, include_slice = {})
        if serializer.is_a?(ActiveModel::Serializer::CollectionSerializer)
          return serializer.map { |child| process_resource(child, include_slice) }
        end
        return unless serializer.respond_to?(:rdf_subject) || serializer.object.respond_to?(:rdf_subject)
        return false unless @resource_identifiers.add?(serializer.read_attribute_for_serialization(:rdf_subject))
        resource_object_for(serializer, include_slice)
        true
      end

      def relationships_for(serializer, requested_associations, include_slice)
        include_directive = JSONAPI::IncludeDirective.new(requested_associations, allow_wildcard: true)
        serializer.associations(include_directive, include_slice).each do |association|
          Relationship.new(serializer, instance_options, association).triples.each do |triple|
            @repository << triple
          end
        end
      end

      def resource_object_for(serializer, include_slice = {})
        type = type_for(serializer, instance_options).to_s
        serializer.fetch(self) do
          break nil if serializer.read_attribute_for_serialization(:rdf_subject).nil?
          requested_fields = fieldset&.fields_for(type)
          attributes_for(serializer, requested_fields)
          custom_triples_for(serializer)
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
# rubocop:enable Metrics/ClassLength
