# frozen_string_literal: true

module ActiveModel
  class Serializer
    class_attribute :_statements

    class << self
      def statements(attribute)
        self._statements ||= []
        self._statements << attribute
      end

      alias triples statements
    end
  end
end
