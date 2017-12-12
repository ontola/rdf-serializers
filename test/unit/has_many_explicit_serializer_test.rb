# frozen_string_literal: true

require 'test_helper'

# Test 'has_many :assocs, serializer: AssocXSerializer'
class HasManyExplicitSerializerTest < ActiveSupport::TestCase
  def setup
    @post = Post.new(title: 'New Post', body: 'Body')
    @author = Author.new(name: 'Jane Blogger')
    @author.posts = [@post]
    @post.author = @author
    @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
    @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
    @post.comments = [@first_comment, @second_comment]
    @first_comment.post = @post
    @first_comment.author = nil
    @second_comment.post = @post
    @second_comment.author = nil
    @blog = Blog.new(id: 23, name: 'AMS Blog')
    @post.blog = @blog

    @serializer = PostPreviewSerializer.new(@post)
    @adapter = ActiveModelSerializers::Adapter::RDF.new(
      @serializer,
      include: %i[comments author]
    )
  end

  def test_includes_comments
    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://post/post> <http://test.org/comments> <https://comment/1> .',
      '<https://post/post> <http://test.org/comments> <https://comment/2> .',
      '<https://post/post> <http://test.org/body> "Body" .',
      '<https://post/post> <http://test.org/title> "New Post" .',
      '<https://post/post> <http://test.org/author> <https://author/author> .',
      '<https://comment/1> <http://test.org/post> <https://post/post> .',
      '<https://comment/2> <http://test.org/post> <https://post/post> .',
      '<https://author/author> <http://test.org/posts> <https://post/post> .'
    )
  end

  def test_explicit_serializer_with_null_resource
    @post.author = nil

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://post/post> <http://test.org/comments> <https://comment/1> .',
      '<https://post/post> <http://test.org/comments> <https://comment/2> .',
      '<https://post/post> <http://test.org/body> "Body" .',
      '<https://post/post> <http://test.org/title> "New Post" .',
      '<https://comment/1> <http://test.org/post> <https://post/post> .',
      '<https://comment/2> <http://test.org/post> <https://post/post> .'
    )
  end

  def test_explicit_serializer_with_null_collection
    @post.comments = []

    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://post/post> <http://test.org/body> "Body" .',
      '<https://post/post> <http://test.org/title> "New Post" .',
      '<https://post/post> <http://test.org/author> <https://author/author> .',
      '<https://author/author> <http://test.org/posts> <https://post/post> .'
    )
  end
end
