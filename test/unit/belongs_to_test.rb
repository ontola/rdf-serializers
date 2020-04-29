# frozen_string_literal: true

require 'test_helper'

class BelongsToTest < ActiveSupport::TestCase
  def setup
    @author = Author.new(id: 1, name: 'Steve K.')
    @author.bio = nil
    @author.roles = []
    @blog = Blog.new(id: 23, name: 'AMS Blog')
    @post = Post.new(id: 42, title: 'New Post', body: 'Body')
    @anonymous_post = Post.new(id: 43, title: 'Hello!!', body: 'Hello, world!!')
    @comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
    @post.comments = [@comment]
    @post.blog = @blog
    @anonymous_post.comments = []
    @anonymous_post.blog = nil
    @comment.post = @post
    @comment.author = nil
    @post.author = @author
    @anonymous_post.author = nil
    @blog = Blog.new(id: 1, name: 'My Blog!!')
    @blog.writer = @author
    @blog.articles = [@post, @anonymous_post]
    @author.posts = []
  end

  def test_includes_post_id
    serializer(@comment)

    assert_ntriples(
      serializer.dump(:ntriples),
      '<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .',
      '<https://comment/1> <http://test.org/post> <https://post/42> .'
    )
  end

  def test_includes_linked_post
    serializer(@comment, include: [:post])

    assert_ntriples(
      serializer.dump(:ntriples),
      '<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .',
      '<https://comment/1> <http://test.org/post> <https://post/42> .',
      '<https://post/42> <http://test.org/author> <https://author/1> .',
      '<https://post/42> <http://test.org/blog> <https://blog/999> .',
      '<https://post/42> <http://test.org/comments> <https://comment/1> .',
      '<https://post/42> <http://test.org/name> "New Post" .',
      '<https://post/42> <http://test.org/text> "Body" .'
    )
  end

  def test_limiting_linked_post_fields
    serializer(@comment, include: [:post], fields: { post: %i[title comments blog author] })

    assert_ntriples(
      serializer.dump(:ntriples),
      '<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .',
      '<https://comment/1> <http://test.org/post> <https://post/42> .',
      '<https://post/42> <http://test.org/author> <https://author/1> .',
      '<https://post/42> <http://test.org/blog> <https://blog/999> .',
      '<https://post/42> <http://test.org/comments> <https://comment/1> .',
      '<https://post/42> <http://test.org/name> "New Post" .'
    )
  end

  def test_include_nil_author
    serializer(@anonymous_post)

    assert_ntriples(
      serializer.dump(:ntriples),
      '<https://post/43> <http://test.org/name> "Hello!!" .',
      '<https://post/43> <http://test.org/blog> <https://blog/999> .',
      '<https://post/43> <http://test.org/text> "Hello, world!!" .'
    )
  end
end
