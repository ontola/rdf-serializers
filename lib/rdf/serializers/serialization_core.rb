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
        def relationships_hextuples(record, relationships = nil, fieldset = nil, includes_list = [], params = {}, resources_to_include = {})
          relationships = relationships_to_serialize if relationships.nil?
          relationships = relationships.slice(*fieldset) if fieldset.present?
          relationships = [] if fieldset == []

          statements = []
          relationships.each do |key, relationship|
            nested_includes = includes_list.present? ? includes_list[key] : nil
            statements.concat relationship.serialize_hex(record, nested_includes, params, resources_to_include)
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

        def record_hextuples(record, fieldset, includes_list, params = {}, resources_to_include = {})
          record_hex = []
          record_hex.concat attributes_hextuples(record, fieldset, params) if attributes_to_serialize.present?
          record_hex.concat statements_hextuples(record, params)
          if relationships_to_serialize.present?
            record_hex.concat relationships_hextuples(record, nil, fieldset, includes_list, params, resources_to_include)
          end
          record_hex
        end
      end
    end
  end
end
