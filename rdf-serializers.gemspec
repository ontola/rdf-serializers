# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rdf/serializers/version'

Gem::Specification.new do |s|
  s.name = 'rdf-serializers'
  s.version = RDFSerializers::Version::VERSION

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Arthur Dingemans']
  s.date = '2017-12-11'
  s.summary = 'Adds RDF serialization, like n-triples or turtle, to active model serializers'
  s.email = 'arthur@argu.co'
  s.files = Dir.glob('lib/**/*.rb')
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = 'https://github.com/argu-co/rdf-serializers'
  s.require_paths = ['lib']

  s.add_runtime_dependency 'active_model_serializers', '~> 0.10'
  s.add_runtime_dependency 'railties', '>= 4.2.0', '< 6'
  s.add_runtime_dependency 'rdf', '~> 3.0'
end
