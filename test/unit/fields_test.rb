# frozen_string_literal: true

require 'test_helper'

class FieldsTest < ActiveSupport::TestCase
  def setup
    @author = Author.new(id: 1, name: 'Lucas', birthday: '10.01.1990')
    @comment1 = Comment.new(id: 7, body: 'cool', author: @author)
    @comment2 = Comment.new(id: 12, body: 'awesome', author: @author)
    @post = Post.new(id: 1337, title: 'Title 1', body: 'Body 1',
                     author: @author, comments: [@comment1, @comment2])
    @comment1.post = @post
    @comment2.post = @post

    @serializer = PostSerializer.new(@post)
  end

  def test_fields_attributes
    adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer, fields: { posts: [:title] })
    assert_ntriples(
      adapter.dump(:ntriples),
      '<https://post/1337> <http://test.org/name> "Title 1" .'
    )
  end

  def test_fields_relationships
    adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer, fields: { posts: [:author] })
    assert_ntriples(
      adapter.dump(:ntriples),
      '<https://post/1337> <http://test.org/author> <https://author/1> .'
    )
  end

  def test_fields_included
    adapter = ActiveModelSerializers::Adapter::RDF.new(
      @serializer,
      include: 'comments',
      fields: { posts: [:author], comments: [:body] }
    )
    assert_ntriples(
      adapter.dump(:ntriples),
      '<https://comment/7> <http://test.org/text> "cool" .',
      '<https://comment/12> <http://test.org/text> "awesome" .',
      '<https://post/1337> <http://test.org/author> <https://author/1> .'
    )
  end
end
