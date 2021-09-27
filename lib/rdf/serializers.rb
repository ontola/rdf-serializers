# frozen_string_literal: true

require 'fast_jsonapi'

require 'rdf/serializers/lookup_chain'
require 'rdf/serializers/config'
require 'rdf/serializers/hextuple_serializer'
require 'rdf/serializers/data_type_helper'
require 'rdf/serializers/hdnjson_parser'
require 'rdf/serializers/serialization_core'
require 'rdf/serializers/object_serializer'
require 'rdf/serializers/scalar'
require 'rdf/serializers/relationship'
require 'rdf/serializers/nil_serializer'
require 'rdf/serializers/list_serializer'

module RDF
  module Serializers
    class << self
      # Extracted from active_model_serializers
      # @param resource [ActiveRecord::Base, ActiveModelSerializers::Model]
      # @return [ActiveModel::Serializer]
      #   Preferentially returns
      #   1. resource.serializer_class
      #   2. ArraySerializer when resource is a collection
      #   3. options[:serializer]
      #   4. lookup serializer when resource is a Class
      def serializer_for(resource_or_class, options = {})
        if resource_or_class.respond_to?(:serializer_class)
          resource_or_class.serializer_class
        elsif resource_or_class.respond_to?(:to_ary)
          unless resource_or_class.all? { |resource| resource.is_a?(resource_or_class.first.class) }
            return ListSerializer
          end

          serializer_for(resource_or_class.first)
        else
          resource_class = resource_or_class.class == Class ? resource_or_class : resource_or_class.class
          options.fetch(:serializer) { get_serializer_for(resource_class, options[:namespace]) }
        end
      end

      private

      # Extracted from active_model_serializers
      # Find a serializer from a class and caches the lookup.
      # Preferentially returns:
      #   1. class name appended with "Serializer"
      #   2. try again with superclass, if present
      #   3. nil
      def get_serializer_for(klass, namespace = nil)
        return nil unless config.serializer_lookup_enabled

        return NilSerializer if klass == NilClass

        cache_key = ActiveSupport::Cache.expand_cache_key(klass, namespace)
        serializers_cache.fetch_or_store(cache_key) do
          # NOTE(beauby): When we drop 1.9.3 support we can lazify the map for perfs.
          lookup_chain = serializer_lookup_chain_for(klass, namespace)
          serializer_class = lookup_chain.map(&:safe_constantize).find do |x|
            x&.include?(FastJsonapi::SerializationCore)
          end

          if serializer_class
            serializer_class
          elsif klass.superclass
            get_serializer_for(klass.superclass, namespace)
          end
        end
      end

      # Extracted from active_model_serializers
      # Used to cache serializer name => serializer class
      # when looked up by Serializer.get_serializer_for.
      def serializers_cache
        @serializers_cache ||= Concurrent::Map.new
      end

      def serializer_lookup_chain_for(klass, namespace = nil)
        lookups = config.serializer_lookup_chain
        Array[*lookups].flat_map do |lookup|
          lookup.call(klass, namespace)
        end.compact
      end
    end
  end
end
