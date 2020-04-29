# frozen_string_literal: true

require 'test_helper'

class HasManyTest < ActiveSupport::TestCase
  class ModelWithoutSerializer < ::Model
    attr_accessor :id, :name
  end

  def setup
    @author = Author.new(id: 1, name: 'Steve K.')
    @author.posts = []
    @author.bio = nil
    @post = Post.new(id: 1, title: 'New Post', body: 'Body')
    @post_without_comments = Post.new(id: 2, title: 'Second Post', body: 'Second')
    @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
    @first_comment.author = nil
    @second_comment = Comment.new(id: 2, body: 'ANOTHER COMMENT')
    @second_comment.author = nil
    @post.comments = [@first_comment, @second_comment]
    @post_without_comments.comments = []
    @first_comment.post = @post
    @second_comment.post = @post
    @post.author = @author
    @post_without_comments.author = nil
    @blog = Blog.new(id: 1, name: 'My Blog!!')
    @blog.writer = @author
    @blog.articles = [@post]
    @post.blog = @blog
    @post_without_comments.blog = nil
    @tag = ModelWithoutSerializer.new(id: 1, name: '#hash_tag')
    @post.tags = [@tag]
  end

  def test_links_comments
    serializer(@post)

    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/1> .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/2> .')
    assert_not serializer.dump(:ntriples).include?('<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .')
    assert_not serializer.dump(:ntriples).include?('<https://comment/1> <http://test.org/post> <https://post/1> .')
  end

  def test_relationships_can_be_whitelisted_via_fields
    serializer(@post, fields: { post: [:author] })

    assert_equal serializer.dump(:ntriples), "<https://post/1> <http://test.org/author> <https://author/1> .\n"
  end

  def test_includes_linked_comments
    serializer(@post, include: [:comments])

    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/name> "New Post" .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/text> "Body" .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/blog> <https://blog/999> .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/author> <https://author/1> .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/1> .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/2> .')
    assert serializer.dump(:ntriples).include?('<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .')
    assert serializer.dump(:ntriples).include?('<https://comment/1> <http://test.org/post> <https://post/1> .')
    assert serializer.dump(:ntriples).include?('<https://comment/2> <http://test.org/text> "ANOTHER COMMENT" .')
    assert serializer.dump(:ntriples).include?('<https://comment/2> <http://test.org/post> <https://post/1> .')
  end

  def test_limit_fields_of_linked_comments
    serializer(@post, include: [:comments], fields: { comment: %i[id post author] })

    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/name> "New Post" .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/text> "Body" .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/blog> <https://blog/999> .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/author> <https://author/1> .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/1> .')
    assert serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/2> .')
    assert_not serializer.dump(:ntriples).include?('<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .')
    assert serializer.dump(:ntriples).include?('<https://comment/1> <http://test.org/post> <https://post/1> .')
    assert_not serializer.dump(:ntriples).include?('<https://comment/2> <http://test.org/text> "ANOTHER COMMENT" .')
    assert serializer.dump(:ntriples).include?('<https://comment/2> <http://test.org/post> <https://post/1> .')
  end

  def test_no_include_linked_if_comments_is_empty
    serializer(@post_without_comments)

    assert_not serializer.dump(:ntriples).include?('<https://post/2> <http://test.org/comments>')
  end

  def test_has_many_with_no_serializer
    @serializer = PostWithTagsSerializer.new(@post)

    assert_raise(NameError) do
      assert @serializer.dump(:ntriples).include?('<https://post/1> <http://test.org/name> "New Post" .')
    end
  end
end
