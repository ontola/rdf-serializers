# frozen_string_literal: true

require 'test_helper'

class DataTypesTest < ActiveSupport::TestCase
  class Resource < Model
    attr_accessor :attr
  end
  class ResourceSerializer < ApplicationSerializer
    attribute :attr, predicate: RDF::TEST[:attr]
  end

  def setup
    @resource = Resource.new
    @serializer = ResourceSerializer.new(@resource)
  end

  def test_array
    @resource.attr = [1, '2']

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://data_types_test/resource/> <http://test.org/attr> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .',
      '<https://data_types_test/resource/> <http://test.org/attr> "2" .'
    )
  end

  def test_boolean
    @resource.attr = true

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://data_types_test/resource/> <http://test.org/attr> "true"^^<http://www.w3.org/2001/XMLSchema#boolean> .'
    )
  end

  def test_date
    @resource.attr = Date.new

    assert_ntriples(
      @serializer.dump(:ntriples),
      "<https://data_types_test/resource/> <http://test.org/attr> \"#{@resource.attr.strftime('%F')}\""\
      '^^<http://www.w3.org/2001/XMLSchema#date> .'
    )
  end

  def test_date_time
    @resource.attr = DateTime.new

    assert_ntriples(
      @serializer.dump(:ntriples),
      "<https://data_types_test/resource/> <http://test.org/attr> \"#{@resource.attr.strftime('%FT%TZ')}\""\
      '^^<http://www.w3.org/2001/XMLSchema#dateTime> .'
    )
  end

  def test_decimal
    @resource.attr = RDF::Literal::Decimal.new(1)

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://data_types_test/resource/> <http://test.org/attr> "1.0"^^<http://www.w3.org/2001/XMLSchema#decimal> .'
    )
  end

  def test_double
    @resource.attr = 1.0

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://data_types_test/resource/> <http://test.org/attr> "1.0"^^<http://www.w3.org/2001/XMLSchema#double> .'
    )
  end

  def test_integer
    @resource.attr = 1

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://data_types_test/resource/> <http://test.org/attr> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .'
    )
  end

  def test_time_with_zone
    @resource.attr = 1.year.ago
    expected = @resource.attr.strftime(RDF::Literal::DateTime::FORMAT).sub('+00:00', 'Z').sub('.000', '')

    assert_ntriples(
      @serializer.dump(:ntriples),
      "<https://data_types_test/resource/> <http://test.org/attr> \"#{expected}\""\
      '^^<http://www.w3.org/2001/XMLSchema#dateTime> .'
    )
  end

  def test_symbol
    @resource.attr = :symbol

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://data_types_test/resource/> <http://test.org/attr> "symbol"^^<http://www.w3.org/2001/XMLSchema#token> .'
    )
  end
end
