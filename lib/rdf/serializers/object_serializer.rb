# frozen_string_literal: true

module RDF
  module Serializers
    module ObjectSerializer
      HEX_SUBJECT = 0
      HEX_PREDICATE = 1
      HEX_OBJECT = 2
      HEX_DATATYPE = 3
      HEX_LANGUAGE = 4
      HEX_GRAPH = 5

      extend ActiveSupport::Concern
      include FastJsonapi::ObjectSerializer
      include DataTypeHelper
      include SerializationCore

      def dump(*args, **options)
        case args.first
        when :hndjson
          render_hndjson
        else
          render_repository(*args, options)
        end
      end

      def triples(*args, **options)
        if include_named_graphs?(*args)
          repository.triples(*args, options)
        else
          repository.project_graph(nil).triples(*args, options)
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
            value_to_hex(statement[0], statement[1], statement[2], statement[3])
          else
            value_to_hex(statement.subject.to_s, statement.predicate, statement.object, statement.graph_name)
          end
        end.compact
      end

      def repository
        return @repository if @repository.present?

        @repository = ::RDF::Repository.new

        serializable_hextuples.compact.each do |hextuple|
          object =
            case hextuple[HEX_DATATYPE]
            when 'http://www.w3.org/1999/02/22-rdf-syntax-ns#namedNode'
              RDF::URI.new(hextuple[HEX_OBJECT])
            when 'http://www.w3.org/1999/02/22-rdf-syntax-ns#blankNode'
              blank_node(hextuple[HEX_OBJECT].sub('_:', ''))
            else
              xsd_to_rdf(hextuple[HEX_DATATYPE], hextuple[HEX_OBJECT], language: hextuple[HEX_LANGUAGE].presence)
            end
          subject =
            if hextuple[HEX_SUBJECT].is_a?(RDF::Resource)
              hextuple[HEX_SUBJECT]
            elsif hextuple[HEX_SUBJECT].start_with?('_')
              blank_node(hextuple[HEX_SUBJECT].sub('_:', ''))
            else
              RDF::URI(hextuple[HEX_SUBJECT])
            end

          @repository << RDF::Statement.new(
            subject,
            RDF::URI(hextuple[HEX_PREDICATE]),
            object,
            graph_name: hextuple[HEX_GRAPH] && RDF::URI(hextuple[HEX_GRAPH])
          )
        end

        @repository
      end

      def render_hndjson
        serializable_hextuples
          .map { |s| Oj.fast_generate(s) }
          .join("\n")
      end

      def render_repository(*args, options)
        if include_named_graphs?(*args)
          repository.dump(*args, options)
        else
          repository.project_graph(nil).dump(*args, options)
        end
      end

      def serializable_hextuples
        if is_collection?(@resource, @is_collection)
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
          relation = super
          relation.association = association
          relation.image = image
          relation.predicate = predicate

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
      end
    end
  end
end
