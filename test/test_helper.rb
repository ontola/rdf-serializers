# frozen_string_literal: true

# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'
require 'bundler/setup'

require 'pry'
require 'rails'
require 'rdf'
require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/railtie'
require 'active_model_serializers'
require 'rdf/serializers'
require 'fileutils'
FileUtils.mkdir_p(File.expand_path('../tmp/cache', __dir__))

gem 'minitest'
require 'minitest'
require 'minitest/autorun'

RDF::TEST = RDF::Vocabulary.new('http://test.org/')

require 'support/rails_app'

require 'support/before_setup'

require 'support/rails5_shims'

require 'support/test_helpers'

require 'fixtures/poro'

require 'rdf/serializers/renderers'

RDF::Serializers::Renderers.register(:ntriples)
