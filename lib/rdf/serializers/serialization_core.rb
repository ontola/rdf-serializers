# frozen_string_literal: true

module RDF
  module Serializers
    module SerializationCore
      extend ActiveSupport::Concern

      included do
        include HextupleSerializer
        extend HextupleSerializer
      end

      class_methods do
        def relationships_hextuples(record, relationships = nil, fieldset = nil, includes_list = [], params = {})
          relationships = relationships_to_serialize if relationships.nil?
          relationships = relationships.slice(*fieldset) if fieldset.present?
          relationships = [] if fieldset == []

          statements = []
          relationships.each do |key, relationship|
            included = includes_list.present? && includes_list.include?(key)
            statements.concat relationship.serialize_hex(record, included, params)
          end

          statements
        end

        def attributes_hextuples(record, fieldset = nil, params = {})
          attributes = attributes_to_serialize
          attributes = attributes.slice(*fieldset) if fieldset.present?
          attributes = {} if fieldset == []

          statements = attributes.flat_map do |_k, attr|
            attr.serialize_hex(record, params)
          end

          statements.compact
        end

        def statements_hextuples(record, params = {})
          statements = []

          _statements&.map do |key|
            send(key, record, params).each do |statement|
              statements << if statement.is_a?(Array)
                value_to_hex(statement[0], statement[1], statement[2], statement[3], params)
              else
                value_to_hex(statement.subject.to_s, statement.predicate, statement.object, statement.graph_name, params)
              end
            end
          end

          statements.compact
        end

        def record_hextuples(record, fieldset, includes_list, params = {})
          if cache_store_instance
            record_hex = Rails.cache.fetch(record.cache_key, expires_in: cache_length, race_condition_ttl: race_condition_ttl) do
              temp_hex = []
              temp_hex.concat attributes_hextuples(record, fieldset, params) if attributes_to_serialize.present?
              temp_hex.concat statements_hextuples(record, params)
              if cachable_relationships_to_serialize.present?
                temp_hex.concat relationships_hextuples(record, cachable_relationships_to_serialize, fieldset, includes_list, params)
              end
              temp_hex
            end
            if uncachable_relationships_to_serialize.present?
              record_hex.concat relationships_hextuples(record, uncachable_relationships_to_serialize, fieldset, includes_list, params)
            end
          else
            record_hex = []
            record_hex.concat attributes_hextuples(record, fieldset, params) if attributes_to_serialize.present?
            record_hex.concat statements_hextuples(record, params)
            if relationships_to_serialize.present?
              record_hex.concat relationships_hextuples(record, nil, fieldset, includes_list, params)
            end
          end
          record_hex
        end

        def get_included_records_hex(record, includes_list, known_included_objects, fieldsets, params = {})
          return unless includes_list.present?
          return [] unless relationships_to_serialize

          includes_list = parse_includes_list(includes_list)

          includes_list.each_with_object([]) do |include_item, included_records|
            relationship_item = relationships_to_serialize[include_item.first]

            next unless relationship_item&.include_relationship?(record, params)

            included_objects = Array(relationship_item.fetch_associated_object(record, params))
            next if included_objects.empty?

            static_serializer = relationship_item.static_serializer
            static_record_type = relationship_item.static_record_type

            included_objects.each do |inc_obj|
              serializer = static_serializer || relationship_item.serializer_for(inc_obj, params)
              record_type = static_record_type || serializer.record_type

              if include_item.last.any?
                serializer_records = serializer.get_included_records_hex(inc_obj, include_item.last, known_included_objects, fieldsets, params)
                included_records.concat(serializer_records) unless serializer_records.empty?
              end

              code = "#{record_type}_#{serializer.iri_from_record(inc_obj)}"
              next if known_included_objects.include?(code)

              known_included_objects << code

              included_records.concat(
                serializer.record_hextuples(inc_obj, fieldsets[record_type], includes_list, params)
              )
            end
          end
        end
      end
    end
  end
end
