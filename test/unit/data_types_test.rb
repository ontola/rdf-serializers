# frozen_string_literal: true

require 'test_helper'

class DataTypesTest < ActiveSupport::TestCase
  class Resource < Model
    attributes :attr
  end
  class ResourceSerializer < ApplicationSerializer
    attribute :attr, predicate: RDF::TEST[:attr]

    def rdf_subject
      RDF::URI('https://example.com')
    end
  end

  def setup
    @resource = Resource.new
    @serializer = ResourceSerializer.new(@resource)
    @adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer)
    ActionController::Base.cache_store.clear
  end

  def test_array
    @resource.attr = [1, '2']

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://example.com> <http://test.org/attr> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .',
      '<https://example.com> <http://test.org/attr> "2" .'
    )
  end

  def test_boolean
    @resource.attr = true

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://example.com> <http://test.org/attr> "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .'
    )
  end

  def test_date
    @resource.attr = Date.new

    assert_ntriples(
      @adapter.dump(:ntriples),
      "<https://example.com> <http://test.org/attr> \"#{@resource.attr.strftime('%F')}\""\
      '^^<http://www.w3.org/2001/XMLSchema#date> .'
    )
  end

  def test_date_time
    @resource.attr = DateTime.new

    assert_ntriples(
      @adapter.dump(:ntriples),
      "<https://example.com> <http://test.org/attr> \"#{@resource.attr.strftime('%FT%TZ')}\""\
      '^^<http://www.w3.org/2001/XMLSchema#dateTime> .'
    )
  end

  def test_decimal
    @resource.attr = RDF::Literal::Decimal.new(1)

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://example.com> <http://test.org/attr> "1.0"^^<http://www.w3.org/2001/XMLSchema#decimal> .'
    )
  end

  def test_double
    @resource.attr = 1.0

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://example.com> <http://test.org/attr> "1.0"^^<http://www.w3.org/2001/XMLSchema#double> .'
    )
  end

  def test_integer
    @resource.attr = 1

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://example.com> <http://test.org/attr> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .'
    )
  end

  def test_time_with_zone
    @resource.attr = 1.year.ago
    expected = @resource.attr.strftime(RDF::Literal::DateTime::FORMAT).sub('+00:00', 'Z').sub('.000', '')

    assert_ntriples(
      @adapter.dump(:ntriples),
      "<https://example.com> <http://test.org/attr> \"#{expected}\""\
      '^^<http://www.w3.org/2001/XMLSchema#dateTime> .'
    )
  end

  def test_symbol
    @resource.attr = :symbol

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://example.com> <http://test.org/attr> "symbol"^^<http://www.w3.org/2001/XMLSchema#token> .'
    )
  end
end
