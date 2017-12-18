# RDF Serializers

<a href="https://travis-ci.org/argu-co/rdf-serializers"><img src="https://travis-ci.org/argu-co/rdf-serializers.svg?branch=master" alt="Build Status"></a>

## About

RDF Serializers enables serialization to RDF formats. It uses your existing [active_model_serializers](https://github.com/rails-api/active_model_serializers) serializers, with a few modifications.
The serialization itself is done by the [rdf](https://github.com/ruby-rdf/rdf) gem.

This was built at [Argu](https://argu.co). If you like what we do, these technologies
or open data in general, send us [a mail](mailto:info@argu.co).

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

It's recommended to reuse existing vocabularies provided by the `rdf` gem, and add your own for missing predicates. 
For example:
```
  MY_VOCAB = RDF::Vocabulary.new('http://example.com/')
  SCHEMA = RDF::Vocabulary.new('http://schema.org/')
```

Now add the predicates to your serializers. 

Old: 
```ruby
class PostSerializer < ActiveModel::Serializer
  attributes :title, :body
  belongs_to :author
  has_many :comments
end
```

New:
```ruby
class PostSerializer < ActiveModel::Serializer
  attribute :title, predicate: SCHEMA[:name]
  attribute :body, predicate: SCHEMA[:text]
  belongs_to :author, predicate: MY_VOCAB[:author]
  has_many :comments, predicate: MY_VOCAB[:comments]
end
```

For RDF serialization, you are required to add an `iri` method to your serializer, which must return a `RDF::URI`. For example:
```ruby
  def iri
    RDF::URI(Rails.application.routes.url_helpers.comment_url(object))
  end
```

In contrast to the JSON API serializer, this rdf serializers don't automatically serialize the `type` and `id` of your model. 
It's recommended to add `attribute :type, predicate: RDF[:type]` and a method defining the type to your serializers to fix this.

### Adding meta triples

You can add additional triples to the serialization from the controller, for example:
```ruby
render nt: model, meta: [[RDF::URI('https://example.com'), RDF::TEST[:someValue], 1]]
```

## Contributing

The usual stuff. Open an issue to discuss a change, open pull requests directly for bugfixes and refactors.
