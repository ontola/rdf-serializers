# frozen_string_literal: true

module RDF
  module Serializers
    module Statements
      extend ActiveSupport::Concern

      included do
        class_attribute :_statements
        self._statements ||= []
      end

      module ClassMethods
        def inherited(base)
          super
          base._statements = _statements.dup
        end

        def statements(attribute)
          self._statements << attribute
        end
      end
    end
  end
end

FastJsonapi::ObjectSerializer.include(RDF::Serializers::Statements)
