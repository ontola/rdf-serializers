# frozen_string_literal: true

module RDF
  module Serializers
    class HndJSONParser
      include DataTypeHelper

      HEX_SUBJECT = 0
      HEX_PREDICATE = 1
      HEX_OBJECT = 2
      HEX_DATATYPE = 3
      HEX_LANGUAGE = 4
      HEX_GRAPH = 5

      def parse_body(body)
        body.split("\n").map { |line| parse_hex(JSON.parse(line)) }
      end

      def parse_hex(hex)
        subject = parse_subject(hex[HEX_SUBJECT])
        predicate = RDF::URI(hex[HEX_PREDICATE])
        object = parse_object(hex[HEX_OBJECT], hex[HEX_DATATYPE], hex[HEX_LANGUAGE])
        graph = hex[HEX_GRAPH].present? ? RDF::URI(hex[HEX_GRAPH]) : RDF::Serializers.config.default_graph

        RDF::Statement.new(
          subject,
          predicate,
          object,
          graph_name: graph
        )
      end

      private

      def blank_node(id)
        @blank_nodes ||= {}
        @blank_nodes[id] ||= RDF::Node(id)
      end

      def parse_object(value, datatype, language)
        case datatype
        when 'http://www.w3.org/1999/02/22-rdf-syntax-ns#namedNode'
          RDF::URI(value)
        when 'http://www.w3.org/1999/02/22-rdf-syntax-ns#blankNode'
          blank_node(value.sub('_:', ''))
        when language
          RDF::Literal(value, datatype: RDF.langString, language: language)
        else
          xsd_to_rdf(datatype, value, language: language.presence)
        end
      end

      def parse_subject(subject)
        if subject.is_a?(RDF::Resource)
          subject
        elsif subject.start_with?('_')
          blank_node(subject.sub('_:', ''))
        else
          RDF::URI(subject)
        end
      end

      class << self
        def parse(body)
          new.parse_body(body)
        end
      end
    end
  end
end
