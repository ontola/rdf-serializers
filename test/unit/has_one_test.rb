# frozen_string_literal: true

require 'test_helper'

class HasOneTest < ActiveSupport::TestCase
  def setup
    @author = Author.new(id: 1, name: 'Steve K.')
    @bio = Bio.new(id: 43, content: 'AMS Contributor')
    @author.bio = @bio
    @bio.author = @author
    @post = Post.new(id: 42, title: 'New Post', body: 'Body')
    @anonymous_post = Post.new(id: 43, title: 'Hello!!', body: 'Hello, world!!')
    @comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
    @post.comments = [@comment]
    @anonymous_post.comments = []
    @comment.post = @post
    @comment.author = nil
    @post.author = @author
    @anonymous_post.author = nil
    @blog = Blog.new(id: 1, name: 'My Blog!!')
    @blog.writer = @author
    @blog.articles = [@post, @anonymous_post]
    @author.posts = []
    @author.roles = []

    @serializer = AuthorSerializer.new(@author)
    @adapter = ActiveModelSerializers::Adapter::RDF.new(@serializer, include: %i[bio posts])
  end

  def test_includes_bio_id
    assert_ntriples(
      @adapter.dump(:ntriples),
      '<https://author/1> <http://test.org/id> "1"^^<http://www.w3.org/2001/XMLSchema#integer> .',
      '<https://author/1> <http://test.org/name> "Steve K." .',
      '<https://author/1> <http://test.org/bio> <https://bio/43> .',
      '<https://bio/43> <http://test.org/author> <https://author/1> .',
      '<https://bio/43> <http://test.org/content> "AMS Contributor" .'
    )
  end

  def test_has_one_from_block
    serializer_class = Class.new(ApplicationSerializer) do
      has_one :custom, predicate: RDF::TEST[:custom] do
        {
          id: RDF::URI('https://has.one'),
          type: RDF::TEST[:ignore]
        }
      end
    end
    assert_ntriples(
      ActiveModelSerializers::Adapter::RDF.new(serializer_class.new(@author)).dump(:ntriples),
      '<https://author/1> <http://test.org/custom> <https://has.one> .'
    )
  end
end
