# frozen_string_literal: true

require 'test_helper'

class HasManyTest < ActiveSupport::TestCase
  class ModelWithoutSerializer < ::Model
    attributes :id, :name
  end

  def setup
    ActionController::Base.cache_store.clear
    @author = Author.new(id: 1, name: 'Steve K.')
    @author.posts = []
    @author.bio = nil
    @post = Post.new(id: 1, title: 'New Post', body: 'Body')
    @post_without_comments = Post.new(id: 2, title: 'Second Post', body: 'Second')
    @first_comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
    @first_comment.author = nil
    @second_comment = Comment.new(id: 2, body: 'ZOMG ANOTHER COMMENT')
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
    @serializer = PostSerializer.new(@post)
    @adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer)
  end

  def test_links_comments
    adapter = @adapter
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/1> .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/2> .')
    assert_not adapter.dump(:ntriples).include?('<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .')
    assert_not adapter.dump(:ntriples).include?('<https://comment/1> <http://test.org/post> <https://post/1> .')
  end

  def test_relationships_can_be_whitelisted_via_fields
    adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer, fields: { posts: [:author] })
    assert_equal adapter.dump(:ntriples), "<https://post/1> <http://test.org/author> <https://author/1> .\n"
  end

  def test_includes_linked_comments
    adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer, include: [:comments])
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/name> "New Post" .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/text> "Body" .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/blog> <https://blog/999> .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/author> <https://author/1> .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/1> .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/2> .')
    assert adapter.dump(:ntriples).include?('<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .')
    assert adapter.dump(:ntriples).include?('<https://comment/1> <http://test.org/post> <https://post/1> .')
    assert adapter.dump(:ntriples).include?('<https://comment/2> <http://test.org/text> "ZOMG ANOTHER COMMENT" .')
    assert adapter.dump(:ntriples).include?('<https://comment/2> <http://test.org/post> <https://post/1> .')
  end

  def test_limit_fields_of_linked_comments
    adapter = ActiveModelSerializers::Adapter::RDF.new(
      @serializer,
      include: [:comments],
      fields: { comment: %i[id post author] }
    )
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/name> "New Post" .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/text> "Body" .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/blog> <https://blog/999> .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/author> <https://author/1> .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/1> .')
    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/comments> <https://comment/2> .')
    assert_not adapter.dump(:ntriples).include?('<https://comment/1> <http://test.org/text> "ZOMG A COMMENT" .')
    assert adapter.dump(:ntriples).include?('<https://comment/1> <http://test.org/post> <https://post/1> .')
    assert_not adapter.dump(:ntriples).include?('<https://comment/2> <http://test.org/text> "ZOMG ANOTHER COMMENT" .')
    assert adapter.dump(:ntriples).include?('<https://comment/2> <http://test.org/post> <https://post/1> .')
  end

  def test_no_include_linked_if_comments_is_empty
    serializer = PostSerializer.new(@post_without_comments)
    adapter = ActiveModelSerializers::Adapter::RDF.new(serializer)

    assert_not adapter.dump(:ntriples).include?('<https://post/2> <http://test.org/comments>')
  end

  def test_has_many_with_no_serializer
    post_serializer_class = Class.new(ActiveModel::Serializer) do
      attribute :title, predicate: RDF::TEST[:name]
      has_many :tags, predicate: RDF::TEST[:tags]

      def iri
        RDF::URI("https://#{object.class.name.underscore}/#{object.id}")
      end
    end
    serializer = post_serializer_class.new(@post)
    adapter = ActiveModelSerializers::Adapter::RDF.new(serializer)

    assert adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/name> "New Post" .')
    assert_not adapter.dump(:ntriples).include?('<https://post/1> <http://test.org/tags>')
  end
end
