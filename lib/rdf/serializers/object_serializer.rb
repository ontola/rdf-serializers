# frozen_string_literal: true

require 'oj'

module RDF
  module Serializers
    module ObjectSerializer
      extend ActiveSupport::Concern
      include FastJsonapi::ObjectSerializer
      include SerializationCore

      included do
        class_attribute :_statements
        self._statements ||= []
      end

      def dump(*args, **options)
        case args.first
        when :hndjson
          render_hndjson
        else
          render_repository(*args, **options)
        end
      end

      def triples(*args, **options)
        if include_named_graphs?(*args)
          repository.triples(*args, **options)
        else
          repository.project_graph(nil).triples(*args, **options)
        end
      end

      private

      def blank_node(id)
        @blank_nodes ||= {}
        @blank_nodes[id] ||= RDF::Node(id)
      end

      def hextuples_for_collection
        data = []
        fieldset = @fieldsets[self.class.record_type.to_sym]
        @resource.each do |record|
          data.concat self.class.record_hextuples(record, fieldset, @includes, @params)
          next unless @includes.present?

          data.concat(
            self.class.get_included_records_hex(record, @includes, @known_included_objects, @fieldsets, @params)
          )
        end

        data
      end

      def hextuples_for_one_record
        serializable_hextuples = []

        serializable_hextuples.concat self.class.record_hextuples(
          @resource,
          @fieldsets[self.class.record_type.to_sym],
          @includes,
          @params
        )

        if @includes.present?
          serializable_hextuples.concat self.class.get_included_records_hex(
            @resource,
            @includes,
            @known_included_objects,
            @fieldsets,
            @params
          )
        end

        serializable_hextuples
      end

      def include_named_graphs?(*args)
        ::RDF::Serializers.config.always_include_named_graphs ||
          ::RDF::Writer.for(*args.presence || :nquads).instance_methods.include?(:write_quad)
      end

      def meta_hextuples
        return [] unless @meta.is_a?(Array)

        @meta.map do |statement|
          if statement.is_a?(Array)
            value_to_hex(statement[0], statement[1], statement[2], statement[3], @params)
          else
            value_to_hex(statement.subject.to_s, statement.predicate, statement.object, statement.graph_name, @params)
          end
        end.compact
      end

      def repository
        return @repository if @repository.present?

        @repository = ::RDF::Repository.new
        parser = HndJSONParser.new

        serializable_hextuples.compact.each do |hextuple|
          @repository << parser.parse_hex(hextuple)
        end

        @repository
      end

      def render_hndjson
        serializable_hextuples
          .map { |s| Oj.fast_generate(s) }
          .join("\n")
      end

      def render_repository(*args, **options)
        if include_named_graphs?(*args)
          repository.dump(*args, **options)
        else
          repository.project_graph(nil).dump(*args, **options)
        end
      end

      def serializable_hextuples
        if self.class.is_collection?(@resource, @is_collection)
          hextuples_for_collection + meta_hextuples
        elsif !@resource
          []
        else
          hextuples_for_one_record + meta_hextuples
        end
      end

      class_methods do
        def create_relationship(base_key, relationship_type, options, block)
          association = options.delete(:association)
          image = options.delete(:image)
          predicate = options.delete(:predicate)
          sequence = options.delete(:sequence)
          relation = super
          relation.association = association
          relation.image = image
          relation.predicate = predicate
          relation.sequence = sequence

          relation
        end

        # Checks for the `class_name` property on the Model's association to
        # determine a serializer.
        def association_serializer_for(name)
          model_class_name = self.name.to_s.demodulize.classify.gsub(/Serializer$/, '')
          model_class = model_class_name.safe_constantize

          association_class_name = model_class.try(:reflect_on_association, name)&.class_name

          return nil unless association_class_name

          serializer_for(association_class_name)
        end

        def inherited(base)
          super
          base._statements = _statements.dup
        end

        def serializer_for(name)
          associatopm_serializer = association_serializer_for(name)
          return associatopm_serializer if associatopm_serializer

          begin
            RDF::Serializers.serializer_for(const_get(name.to_s.classify))
          rescue NameError
            raise NameError, "#{self.name} cannot resolve a serializer class for '#{name}'.  " \
                             'Consider specifying the serializer directly through options[:serializer].'
          end
        end

        def statements(attribute)
          self._statements << attribute
        end
      end
    end
  end
end
