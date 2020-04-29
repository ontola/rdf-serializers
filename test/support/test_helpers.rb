# frozen_string_literal: true

module TestHelpers
  module_function

  def assert_ntriples(body, *triples)
    triples.each do |triple|
      assert body.include?(triple), "Expected to find #{triple} in\n#{body}"
    end
    triple_count = body.scan(/\n/).length
    assert_equal(
      triple_count, triples.count,
      "Expected to find #{triples.count} triple(s), but found #{triple_count}:\n#{body}"
    )
  end

  def serializer(resource = nil, options = {})
    @serializer ||=
      RDF::Serializers
      .serializer_for(resource)
      .new(resource, RDF::Serializers::Renderers.transform_opts(options, {}))
  end
end

module ActiveSupport
  class TestCase
    include TestHelpers
  end
end
