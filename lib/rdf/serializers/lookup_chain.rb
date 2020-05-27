# frozen_string_literal: true

module RDF
  module Serializers
    # Extracted from active_model_serializers
    module LookupChain
      # Standard appending of Serializer to the resource name.
      #
      # Example:
      #   Author => AuthorSerializer
      BY_RESOURCE = lambda do |resource_class, _namespace|
        serializer_from(resource_class)
      end

      # Uses the namespace of the resource to find the serializer
      #
      # Example:
      #  British::Author => British::AuthorSerializer
      BY_RESOURCE_NAMESPACE = lambda do |resource_class, _namespace|
        resource_namespace = namespace_for(resource_class)
        serializer_name = serializer_from(resource_class)

        "#{resource_namespace}::#{serializer_name}"
      end

      # Uses the controller namespace of the resource to find the serializer
      #
      # Example:
      #  Api::V3::AuthorsController => Api::V3::AuthorSerializer
      BY_NAMESPACE = lambda do |resource_class, namespace|
        resource_name = resource_class_name(resource_class)
        namespace ? "#{namespace}::#{resource_name}Serializer" : nil
      end

      DEFAULT = [
        BY_NAMESPACE,
        BY_RESOURCE_NAMESPACE,
        BY_RESOURCE
      ].freeze

      module_function

      def namespace_for(klass)
        klass.name.deconstantize
      end

      def resource_class_name(klass)
        klass.name.demodulize
      end

      def serializer_from_resource_name(name)
        "#{name}Serializer"
      end

      def serializer_from(klass)
        name = resource_class_name(klass)
        serializer_from_resource_name(name)
      end
    end
  end
end
