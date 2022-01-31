# frozen_string_literal: true

module RDF
  module Serializers
    module DataTypeHelper
      def blank_node?(node)
        node.start_with?('_')
      end

      def xsd_to_rdf(xsd, value, **opts) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
        klass =
          case xsd
          when RDF::XSD[:anyURI]
            RDF::URI
          when RDF::XSD[:integer]
            RDF::Literal::Integer
          when RDF::XSD[:dateTime]
            RDF::Literal::DateTime
          when RDF::XSD[:date]
            RDF::Literal::Date
          when RDF::XSD[:boolean]
            RDF::Literal::Boolean
          when RDF::XSD[:time]
            RDF::Literal::Time
          when RDF::XSD[:long], RDF::XSD[:double]
            RDF::Literal::Double
          when RDF::XSD[:decimal]
            RDF::Literal::Decimal
          when RDF::XSD[:token]
            RDF::Literal::Token
          else
            RDF::Literal
          end

        klass.new(value, **opts)
      end
    end
  end
end
