# frozen_string_literal: true

class Model < ActiveModelSerializers::Model
  rand(2).zero? && derive_attributes_from_names_and_fix_accessors

  attr_writer :id

  # At this time, just for organization of intent
  class_attribute :association_names
  self.association_names = []

  def self.associations(*names)
    self.association_names |= names.map(&:to_sym)
    # Silence redefinition of methods warnings
    ActiveModelSerializers.silence_warnings do
      attr_accessor(*names)
    end
  end

  def associations
    association_names.each_with_object({}) do |association_name, result|
      result[association_name] = public_send(association_name).freeze
    end.with_indifferent_access.freeze
  end

  def attributes
    super.except(*association_names)
  end
end

class ApplicationSerializer < ActiveModel::Serializer
  def iri
    RDF::URI("https://#{object.class.name.underscore}/#{object.id}")
  end
end

class ModelWithErrors < Model
  attributes :name
end

class Profile < Model
  attributes :name, :description
  associations :comments
end
class ProfileSerializer < ApplicationSerializer
  attribute :name, predicate: RDF::TEST[:name]
  attribute :description, predicate: RDF::TEST[:description]
end

class Author < Model
  attributes :name, :birthday, :active
  associations :posts, :bio, :roles, :comments
end
class AuthorSerializer < ApplicationSerializer
  cache key: 'writer', skip_digest: true
  attribute :id, predicate: RDF::TEST[:id]
  attribute :name, predicate: RDF::TEST[:name]
  attribute :birthday, predicate: RDF::TEST[:birthday]
  attribute :active, predicate: RDF::TEST[:active]
  attribute :roles, predicate: RDF::TEST[:roles]

  has_many :posts, predicate: RDF::TEST[:posts]
  has_one :bio, predicate: RDF::TEST[:bio]
end
class AuthorPreviewSerializer < ApplicationSerializer
  attributes :id
  has_many :posts, predicate: RDF::TEST[:posts]
end

class Comment < Model
  attributes :body, :date
  associations :post, :author, :likes
end
class CommentSerializer < ApplicationSerializer
  cache expires_in: 1.day, skip_digest: true
  attributes :id
  attribute :body, predicate: RDF::TEST[:text]
  belongs_to :post, predicate: RDF::TEST[:post]
  belongs_to :author, predicate: RDF::TEST[:author]
end
class CommentPreviewSerializer < ApplicationSerializer
  attributes :id

  belongs_to :post, predicate: RDF::TEST[:post]
end

class Post < Model
  attributes :title, :body
  associations :author, :comments, :blog, :tags, :related
end
class PostSerializer < ApplicationSerializer
  cache key: 'post', expires_in: 0.1, skip_digest: true
  attribute :title, predicate: RDF::TEST[:name]
  attribute :body, predicate: RDF::TEST[:text]
  belongs_to :author, predicate: RDF::TEST[:author]
  belongs_to :blog, predicate: RDF::TEST[:blog]
  has_many :comments, predicate: RDF::TEST[:comments]

  def blog
    Blog.new(id: 999, name: 'Custom blog')
  end
end
class SpammyPostSerializer < ApplicationSerializer
  attributes :id
  has_many :related, predicate: RDF::TEST[:related]
end
class PostPreviewSerializer < ApplicationSerializer
  attributes :id
  attribute :title, predicate: RDF::TEST[:title]
  attribute :body, predicate: RDF::TEST[:body]

  has_many :comments, serializer: ::CommentPreviewSerializer, predicate: RDF::TEST[:comments]
  belongs_to :author, serializer: ::AuthorPreviewSerializer, predicate: RDF::TEST[:author]
end

class Bio < Model
  attributes :content, :rating
  associations :author
end
class BioSerializer < ApplicationSerializer
  cache except: [:content], skip_digest: true
  attributes :id
  attribute :content, predicate: RDF::TEST[:content]
  attribute :rating, predicate: RDF::TEST[:rating]

  belongs_to :author, predicate: RDF::TEST[:author]
end

class Blog < Model
  attributes :name, :type, :special_attribute
  associations :writer, :articles
end
class BlogSerializer < ApplicationSerializer
  cache key: 'blog'
  attributes :id
  attribute :name, predicate: RDF::TEST[:name]

  belongs_to :writer, predicate: RDF::TEST[:writer]
  has_many :articles, predicate: RDF::TEST[:article]
end

class Role < Model
  attributes :name, :description, :special_attribute
  associations :author
end
class RoleSerializer < ApplicationSerializer
  cache only: %i[name slug], skip_digest: true
  attributes :id
  attribute :name, predicate: RDF::TEST[:name]
  attribute :description, predicate: RDF::TEST[:description]
  attribute :friendly_id, key: :slug, predicate: RDF::TEST[:friendly_id]
  belongs_to :author, predicate: RDF::TEST[:author]

  def friendly_id
    "#{object.name}-#{object.id}"
  end
end

module Spam
  class UnrelatedLink < Model
  end
  class UnrelatedLinkSerializer < ApplicationSerializer
    cache only: [:id]
    attributes :id
  end
end
