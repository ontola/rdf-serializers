# frozen_string_literal: true

module ActiveModel
  class Serializer
    class_attribute :_triples

    def self.triples(attribute)
      self._triples ||= []
      self._triples << attribute
    end
  end
end
