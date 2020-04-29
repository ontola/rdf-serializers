# frozen_string_literal: true

require 'test_helper'

class ControllerTest < ActionController::TestCase
  class TestController < ActionController::Base
    def render_array
      render nt: [post, post2]
    end

    def render_mixed_array
      render nt: [post, profile]
    end

    def render_ntriples
      render nt: profile
    end

    def render_meta
      render nt: profile, meta: [[RDF::URI('https://example.com'), RDF::TEST[:someValue], 1]]
    end

    private

    def post
      @post = Post.new(
        id: 2,
        title: 'Nice',
        body: 'Some plea'
      )
    end

    def post2
      @post = Post.new(
        id: 3,
        title: 'Second post',
        body: 'Text'
      )
    end

    def profile
      @profile = Profile.new(
        id: 1,
        name: 'Name 1',
        description: 'Description 1',
        comments: 'Comments 1'
      )
    end
  end

  tests TestController

  def test_render_array
    get :render_array

    assert_ntriples(
      response.body,
      '<https://post/2> <http://test.org/name> "Nice" .',
      '<https://post/2> <http://test.org/text> "Some plea" .',
      '<https://post/2> <http://test.org/blog> <https://blog/999> .',
      '<https://post/3> <http://test.org/name> "Second post" .',
      '<https://post/3> <http://test.org/text> "Text" .',
      '<https://post/3> <http://test.org/blog> <https://blog/999> .'
    )
  end

  def test_render_mixed_array
    get :render_mixed_array

    assert_ntriples(
      response.body,
      '<https://profile/1> <http://test.org/description> "Description 1" .',
      '<https://profile/1> <http://test.org/name> "Name 1" .',
      '<https://post/2> <http://test.org/name> "Nice" .',
      '<https://post/2> <http://test.org/text> "Some plea" .',
      '<https://post/2> <http://test.org/blog> <https://blog/999> .'
    )
  end

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
