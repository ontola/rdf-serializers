# frozen_string_literal: true

require 'test_helper'

class CollectionTest < ActiveSupport::TestCase
  def setup
    @author = Author.new(id: 1, name: 'Steve K.')
    @author.bio = nil
    @blog = Blog.new(id: 23, name: 'AMS Blog')
    @first_post = Post.new(id: 1, title: 'Hello!!', body: 'Hello, world!!')
    @second_post = Post.new(id: 2, title: 'New Post', body: 'Body')
    @first_post.comments = []
    @second_post.comments = []
    @first_post.blog = @blog
    @second_post.blog = nil
    @first_post.author = @author
    @second_post.author = @author
    @author.posts = [@first_post, @second_post]

    @serializer = ActiveModel::Serializer::CollectionSerializer.new([@first_post, @second_post])
    @adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer)
    ActionController::Base.cache_store.clear
  end

  def test_include_multiple_posts
    adapter = @adapter
    assert_ntriples(
      adapter.dump(:ntriples),
      '<https://post/1> <http://test.org/author> <https://author/1> .',
      '<https://post/1> <http://test.org/name> "Hello!!" .',
      '<https://post/1> <http://test.org/blog> <https://blog/999> .',
      '<https://post/1> <http://test.org/text> "Hello, world!!" .',
      '<https://post/2> <http://test.org/author> <https://author/1> .',
      '<https://post/2> <http://test.org/name> "New Post" .',
      '<https://post/2> <http://test.org/blog> <https://blog/999> .',
      '<https://post/2> <http://test.org/text> "Body" .'
    )
  end

  def test_limiting_fields
    adapter = ActiveModelSerializers::Adapter::RDF.new(
      @serializer,
      fields: { post: %w[title comments blog author] }
    )
    assert_ntriples(
      adapter.dump(:ntriples),
      '<https://post/1> <http://test.org/author> <https://author/1> .',
      '<https://post/1> <http://test.org/name> "Hello!!" .',
      '<https://post/1> <http://test.org/blog> <https://blog/999> .',
      '<https://post/2> <http://test.org/author> <https://author/1> .',
      '<https://post/2> <http://test.org/name> "New Post" .',
      '<https://post/2> <http://test.org/blog> <https://blog/999> .'
    )
  end
end
