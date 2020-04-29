# frozen_string_literal: true

require 'test_helper'

class NestedPost < ::Model; associations :nested_posts end
class NestedPostSerializer
  include RDF::Serializers::ObjectSerializer

  has_many :nested_posts
end

class LinkedTest < ActiveSupport::TestCase
  def setup
    @author1 = Author.new(id: 1, name: 'Steve K.')
    @author2 = Author.new(id: 2, name: 'Tenderlove')
    @bio1 = Bio.new(id: 1, content: 'AMS Contributor')
    @bio2 = Bio.new(id: 2, content: 'Rails Contributor')
    @first_post = Post.new(id: 10, title: 'Hello!!', body: 'Hello, world!!')
    @second_post = Post.new(id: 20, title: 'New Post', body: 'Body')
    @third_post = Post.new(id: 30, title: 'Yet Another Post', body: 'Body')
    @blog = Blog.new(name: 'AMS Blog')
    @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
    @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
    @first_post.blog = @blog
    @second_post.blog = @blog
    @third_post.blog = nil
    @first_post.comments = [@first_comment, @second_comment]
    @second_post.comments = []
    @third_post.comments = []
    @first_post.author = @author1
    @second_post.author = @author2
    @third_post.author = @author1
    @first_comment.post = @first_post
    @first_comment.author = nil
    @second_comment.post = @first_post
    @second_comment.author = nil
    @author1.posts = [@first_post, @third_post]
    @author1.bio = @bio1
    @author1.roles = []
    @author2.posts = [@second_post]
    @author2.bio = @bio2
    @author2.roles = []
    @bio1.author = @author1
    @bio2.author = @author2
    @posts_array = [@first_post, @second_post]
    @comments_array = [@first_comment, @second_comment]
  end

  def test_include_multiple_posts_and_linked_array
    serializer(@posts_array, include: [:comments, author: [:bio]])

    assert_ntriples(
      serializer.dump(:ntriples),
      '<https://bio/2> <http://test.org/content> "Rails Contributor" .',
      '<https://bio/2> <http://test.org/author> <https://author/2> .',
      '<https://author/2> <http://test.org/id> "2"^^<http://www.w3.org/2001/XMLSchema#integer> .',
      '<https://author/2> <http://test.org/bio> <https://bio/2> .',
      '<https://author/2> <http://test.org/posts> <https://post/20> .',
      '<https://author/2> <http://test.org/name> "Tenderlove" .',
      '<https://post/10> <http://test.org/author> <https://author/1> .',
      '<https://post/10> <http://test.org/comments> <https://comment/2> .',
      '<https://post/10> <http://test.org/comments> <https://comment/1> .',
      '<https://post/10> <http://test.org/text> "Hello, world!!" .',
      '<https://post/10> <http://test.org/name> "Hello!!" .',
      '<https://post/10> <http://test.org/blog> <https://blog/999> .',
      '<https://author/1> <http://test.org/id> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .',
      '<https://author/1> <http://test.org/bio> <https://bio/1> .',
      '<https://author/1> <http://test.org/posts> <https://post/30> .',
      '<https://author/1> <http://test.org/posts> <https://post/10> .',
      '<https://author/1> <http://test.org/name> "Steve K." .',
      '<https://bio/1> <http://test.org/content> "AMS Contributor" .',
      '<https://bio/1> <http://test.org/author> <https://author/1> .',
      '<https://comment/2> <http://test.org/text> "ZOMG ANOTHER COMMENT" .',
      '<https://comment/2> <http://test.org/post> <https://post/10> .',
      '<https://post/20> <http://test.org/author> <https://author/2> .',
      '<https://post/20> <http://test.org/text> "Body" .',
      '<https://post/20> <http://test.org/name> "New Post" .',
      '<https://post/20> <http://test.org/blog> <https://blog/999> .',
      '<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .',
      '<https://comment/1> <http://test.org/post> <https://post/10> .'
    )
  end

  def test_include_multiple_posts_and_linked
    serializer(@bio1, include: [author: [:posts]])

    assert_ntriples(
      serializer.dump(:ntriples),
      '<https://author/1> <http://test.org/id> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .',
      '<https://author/1> <http://test.org/posts> <https://post/30> .',
      '<https://author/1> <http://test.org/posts> <https://post/10> .',
      '<https://author/1> <http://test.org/bio> <https://bio/1> .',
      '<https://author/1> <http://test.org/name> "Steve K." .',
      '<https://post/30> <http://test.org/blog> <https://blog/999> .',
      '<https://post/30> <http://test.org/text> "Body" .',
      '<https://post/30> <http://test.org/name> "Yet Another Post" .',
      '<https://post/30> <http://test.org/author> <https://author/1> .',
      '<https://post/10> <http://test.org/blog> <https://blog/999> .',
      '<https://post/10> <http://test.org/comments> <https://comment/1> .',
      '<https://post/10> <http://test.org/comments> <https://comment/2> .',
      '<https://post/10> <http://test.org/text> "Hello, world!!" .',
      '<https://post/10> <http://test.org/name> "Hello!!" .',
      '<https://post/10> <http://test.org/author> <https://author/1> .',
      '<https://bio/1> <http://test.org/content> "AMS Contributor" .',
      '<https://bio/1> <http://test.org/author> <https://author/1> .'
    )
  end

  def test_underscore_model_namespace_for_linked_resource_type
    spammy_post = Post.new(id: 123)
    spammy_post.related = [Spam::UnrelatedLink.new(id: 456)]

    @serializer = SpammyPostSerializer.new(spammy_post)

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://post/123> <http://test.org/related> <https://spam/unrelated_link/456> .'
    )
  end

  def test_multiple_references_to_same_resource
    serializer(@comments_array, include: [:post])

    assert_ntriples(
      serializer.dump(:ntriples),
      '<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .',
      '<https://comment/1> <http://test.org/post> <https://post/10> .',
      '<https://post/10> <http://test.org/text> "Hello, world!!" .',
      '<https://post/10> <http://test.org/author> <https://author/1> .',
      '<https://post/10> <http://test.org/comments> <https://comment/1> .',
      '<https://post/10> <http://test.org/comments> <https://comment/2> .',
      '<https://post/10> <http://test.org/blog> <https://blog/999> .',
      '<https://post/10> <http://test.org/name> "Hello!!" .',
      '<https://comment/2> <http://test.org/text> "ZOMG ANOTHER COMMENT" .',
      '<https://comment/2> <http://test.org/post> <https://post/10> .'
    )
  end

  def test_nil_link_with_specified_serializer
    @first_post.author = nil
    @serializer = PostPreviewSerializer.new(@first_post, include: [:author])

    assert_ntriples(
      @serializer.dump(:ntriples),
      '<https://post/10> <http://test.org/title> "Hello!!" .',
      '<https://post/10> <http://test.org/body> "Hello, world!!" .',
      '<https://post/10> <http://test.org/comments> <https://comment/2> .',
      '<https://post/10> <http://test.org/comments> <https://comment/1> .'
    )
  end
end
