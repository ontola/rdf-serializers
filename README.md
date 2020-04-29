# RDF Serializers

<a href="https://travis-ci.org/ontola/rdf-serializers"><img src="https://travis-ci.org/ontola/rdf-serializers.svg?branch=master" alt="Build Status"></a>

## About

RDF Serializers enables serialization to RDF formats. It uses [fast-jsonapi](https://github.com/fast-jsonapi/fast_jsonapi) serializers, with a few modifications.
The serialization itself is done by the [rdf](https://github.com/ruby-rdf/rdf) gem.

This was built at [Ontola](https://ontola.io/). If you want to know more about our passion for open data, send us [an e-mail](mailto:ontola@argu.co).

## Installation

Add this line to your application's Gemfile:

```
gem 'rdf-serializers'
```

And then execute:

```
$ bundle
```

## Getting started

First, register the formats you wish to serialize to. For example, add the following to `config/initializers/rdf_serializers.rb`:
```ruby
require 'rdf/serializers/renderers'

RDF::Serializers::Renderers.register(:ntriples)
```
This automatically registers the MIME type.

In your controllers, add:
```ruby
respond_to do |format|
  format.nt { render nt: model }
end
```

## Configuration

You can configure the gem using `RDF::Serializers.configure`.
```
RDF::Serializers.configure do |config|
  config.always_include_named_graphs = false # true by default. Whether to include named graphs when the serialization format does not support quads.
  config.default_graph = RDF::URI('https://example.com/graph') # nil by default.
end

```

## Formats

You can register multiple formats, if you add the correct gems. For example, add `rdf-turtle` to your gemfile and put this in the initializer:
```ruby
require 'rdf/serializers/renderers'

opts = {
  prefixes: {
    ns:   'http://rdf.freebase.com/ns/',
    key:  'http://rdf.freebase.com/key/',
    owl:  'http://www.w3.org/2002/07/owl#',
    rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
    rdf:  'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    xsd:  'http://www.w3.org/2001/XMLSchema#'
  }
}

RDF::Serializers::Renderers.register(%i[ntriples turtle], opts)

```

The RDF gem has a list of available [RDF Serialization Formats](https://github.com/ruby-rdf/rdf#rdf-serialization-formats), which includes:
* NTriples
* Turtle
* N3
* RDF/XML
* JSON::LD

and more

## Serializing

Add a predicate to the attributes and relations you wish to serialize.

It's recommended to reuse existing vocabularies provided by the `rdf` gem and the [rdf-vocab](https://github.com/ruby-rdf/rdf-vocab) gem, 
and add your own vocab for missing predicates. One way to be able to access the different vocabs throughout your application is by defining a module:
```
require 'rdf'
require "rdf/vocab"

module NS
  SCHEMA = RDF::Vocab::SCHEMA
  MY_VOCAB = RDF::Vocabulary.new('http://example.com/')
end
```

Now add the predicates to your serializers. 

Old: 
```ruby
class PostSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title, :body
  belongs_to :author
  has_many :comments
end
```

New:
```ruby
class PostSerializer
  include RDF::Serializers::ObjectSerializer
  attribute :title, predicate: NS::SCHEMA[:name]
  attribute :body, predicate: NS::SCHEMA[:text]
  belongs_to :author, predicate: NS::MY_VOCAB[:author]
  has_many :comments, predicate: NS::MY_VOCAB[:comments]
end
```

For RDF serialization, you are required to add an `iri` method to your model, which must return a `RDF::Resource`. For example:
```ruby
  def iri
    RDF::URI(Rails.application.routes.url_helpers.comment_url(object))
  end
```

In contrast to the JSON API serializer, this rdf serializers don't automatically serialize the `type` and `id` of your model. 
It's recommended to add `attribute :type, predicate: RDF[:type]` and a method defining the type to your serializers to fix this.

### Custom statements per model

You can add custom statements to the serialization of a model in the serializer, for example:
```ruby
class PostSerializer
  include RDF::Serializers::ObjectSerializer
  statements :my_custom_statements
  
  def my_custom_statements
    [RDF::Statement.new(RDF::URI('https://example.com'), NS::MY_VOCAB[:fooBar], 1)]
  end
end
```

### Meta statements

You can add additional statements to the serialization in the controller, for example:
```ruby
render nt: model, meta: [RDF::Statement.new(RDF::URI('https://example.com'), NS::MY_VOCAB[:fooBar], 1)]
```

## Contributing

The usual stuff. Open an issue to discuss a change, open pull requests directly for bugfixes and refactors.
