# frozen_string_literal: true

require 'test_helper'

class ControllerTest < ActionController::TestCase
  class TestController < ActionController::Base
    def profile
      @profile = Profile.new(
        id: 1,
        name: 'Name 1',
        description: 'Description 1',
        comments: 'Comments 1'
      )
    end

    def render_ntriples
      render nt: profile
    end

    def render_meta
      render nt: profile, meta: [[RDF::URI('https://example.com'), RDF::TEST[:someValue], 1]]
    end
  end

  tests TestController

  def test_render_ntriples
    get :render_ntriples

    assert_ntriples(
      response.body,
      '<https://profile/1> <http://test.org/description> "Description 1" .',
      '<https://profile/1> <http://test.org/name> "Name 1" .'
    )
  end

  def test_render_meta
    get :render_meta

    assert_ntriples(
      response.body,
      '<https://example.com> <http://test.org/someValue> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .',
      '<https://profile/1> <http://test.org/description> "Description 1" .',
      '<https://profile/1> <http://test.org/name> "Name 1" .'
    )
  end
end
