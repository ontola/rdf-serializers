# frozen_string_literal: true

require 'active_model'

class Model
  include ::ActiveModel::Model

  attr_accessor :id

  # At this time, just for organization of intent
  class_attribute :association_names
  self.association_names = []

  def self.associations(*names)
    self.association_names |= names.map(&:to_sym)

    attr_accessor(*names)
  end

  def associations
    association_names.each_with_object({}) do |association_name, result|
      result[association_name] = public_send(association_name).freeze
    end.with_indifferent_access.freeze
  end

  def iri
    RDF::URI("https://#{self.class.name.underscore}/#{id}")
  end
end

class ApplicationSerializer
  include RDF::Serializers::ObjectSerializer
end

class ModelWithErrors < Model
  attr_accessor :name
end

class Profile < Model
  attr_accessor :name, :description
  associations :comments
end
class ProfileSerializer < ApplicationSerializer
  attribute :name, predicate: RDF::TEST[:name]
  attribute :description, predicate: RDF::TEST[:description]
end

class Author < Model
  attr_accessor :name, :birthday, :active
  associations :posts, :bio, :roles, :comments
end
class AuthorSerializer < ApplicationSerializer
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
  attr_accessor :body, :date
  associations :post, :author, :likes
end
class CommentSerializer < ApplicationSerializer
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
  attr_accessor :title, :body
  associations :author, :comments, :blog, :tags, :related
end
class PostSerializer < ApplicationSerializer
  attribute :title, predicate: RDF::TEST[:name]
  attribute :body, predicate: RDF::TEST[:text]
  belongs_to :author, predicate: RDF::TEST[:author]
  belongs_to :blog, predicate: RDF::TEST[:blog] do
    Blog.new(id: 999, name: 'Custom blog')
  end
  has_many :comments, predicate: RDF::TEST[:comments]
end
class PostWithTagsSerializer < ApplicationSerializer
  attribute :title, predicate: RDF::TEST[:name]
  has_many :tags, predicate: RDF::TEST[:tags]
end
class SpammyPostSerializer < ApplicationSerializer
  attributes :id
  has_many :related, predicate: RDF::TEST[:related], polymorphic: true
end
class PostPreviewSerializer < ApplicationSerializer
  attributes :id
  attribute :title, predicate: RDF::TEST[:title]
  attribute :body, predicate: RDF::TEST[:body]

  has_many :comments, serializer: ::CommentPreviewSerializer, predicate: RDF::TEST[:comments]
  belongs_to :author, serializer: ::AuthorPreviewSerializer, predicate: RDF::TEST[:author]
end

class Bio < Model
  attr_accessor :content, :rating
  associations :author
end
class BioSerializer < ApplicationSerializer
  attributes :id
  attribute :content, predicate: RDF::TEST[:content]
  attribute :rating, predicate: RDF::TEST[:rating]

  belongs_to :author, predicate: RDF::TEST[:author]
end

class Blog < Model
  attr_accessor :name, :type, :special_attribute
  associations :writer, :articles
end
class BlogSerializer < ApplicationSerializer
  attributes :id
  attribute :name, predicate: RDF::TEST[:name]

  belongs_to :writer, predicate: RDF::TEST[:writer], serializer: AuthorSerializer
  has_many :articles, predicate: RDF::TEST[:article], serializer: PostSerializer
end

class Role < Model
  attr_accessor :name, :description, :special_attribute
  associations :author
end
class RoleSerializer < ApplicationSerializer
  attributes :id
  attribute :name, predicate: RDF::TEST[:name]
  attribute :description, predicate: RDF::TEST[:description]
  attribute :friendly_id, key: :slug, predicate: RDF::TEST[:friendly_id] do
    "#{object.name}-#{object.id}"
  end
  belongs_to :author, predicate: RDF::TEST[:author]
end

module Spam
  class UnrelatedLink < Model
  end
  class UnrelatedLinkSerializer < ApplicationSerializer
    attributes :id
  end
end
