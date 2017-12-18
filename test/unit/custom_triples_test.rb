# frozen_string_literal: true

require 'test_helper'

class CustomTriplesTest < ActiveSupport::TestCase
  class CustomTriplesSerializer < ApplicationSerializer
    triples :my_custom_triples

    def my_custom_triples
      [[RDF::URI('https://example.com'), RDF::TEST[:someValue], 1]]
    end
  end

  def test_custom_triples
    adapter = ActiveModelSerializers::Adapter::RDF.new(CustomTriplesSerializer.new(Author.new))
    assert_ntriples(
      adapter.dump(:ntriples),
      '<https://example.com> <http://test.org/someValue> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .'
    )
  end
end
