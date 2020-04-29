# frozen_string_literal: true

require 'test_helper'

class CustomTriplesTest < ActiveSupport::TestCase
  class CustomTriplesSerializer < ApplicationSerializer
    statements :my_custom_triples

    def self.my_custom_triples(_object, _params)
      [RDF::Statement.new(RDF::URI('https://example.com'), RDF::TEST[:someValue], 1)]
    end
  end

  def test_custom_triples
    @serializer = CustomTriplesSerializer.new(Author.new)

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://example.com> <http://test.org/someValue> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .'
    )
  end
end
