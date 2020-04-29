# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rdf/serializers/version'

Gem::Specification.new do |s|
  s.name = 'rdf-serializers'
  s.version = RDFSerializers::Version::VERSION
  s.license = 'MIT'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = ['Arthur Dingemans']
  s.date = File.mtime('lib/rdf/serializers/version.rb').strftime('%Y-%m-%d')
  s.summary = 'Adds RDF serialization, like n-triples or turtle, to active model serializers'
  s.email = 'arthur@argu.co'
  s.files = Dir.glob('lib/**/*.rb')
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = 'https://github.com/ontola/rdf-serializers'
  s.require_paths = ['lib']

  s.add_runtime_dependency 'fast_jsonapi'
  s.add_runtime_dependency 'railties', '>= 4.2.0', '< 7'
  s.add_runtime_dependency 'rdf', '~> 3.0'
end
