# frozen_string_literal: true

source 'https://rubygems.org'
#
# Add a Gemfile.local to locally bundle gems outside of version control
local_gemfile = File.join(File.expand_path(__dir__), 'Gemfile.local')
eval_gemfile local_gemfile if File.readable?(local_gemfile)

# Specify your gem's dependencies in active_model_serializers.gemspec
gemspec

version = ENV['RAILS_VERSION'] || '4.2'

if version == 'master'
  gem 'arel', github: 'rails/arel'
  gem 'rack', github: 'rack/rack'
  gem 'rails', github: 'rails/rails'
  git 'https://github.com/rails/rails.git' do
    gem 'actionpack'
    gem 'activemodel'
    gem 'activerecord', group: :test
    gem 'activesupport'
    gem 'railties'
    # Rails 5
    gem 'actionview'
  end
else
  gem_version = "~> #{version}.0"
  gem 'actionpack', gem_version
  gem 'activemodel', gem_version
  gem 'activerecord', gem_version, group: :test
  gem 'activesupport', gem_version
  gem 'rails', gem_version
  gem 'railties', gem_version
end

# https://github.com/bundler/bundler/blob/89a8778c19269561926cea172acdcda241d26d23/lib/bundler/dependency.rb#L30-L54
@windows_platforms = %i[mswin mingw x64_mingw]

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: (@windows_platforms + [:jruby])

group :bench do
  # https://github.com/rails-api/active_model_serializers/commit/cb4459580a6f4f37f629bf3185a5224c8624ca76
  gem 'benchmark-ips', '>= 2.7.2', require: false, group: :development
end

group :test do
  gem 'byebug', '~> 8.2' if RUBY_VERSION < '2.2'
  gem 'codeclimate-test-reporter', require: false
  gem 'm', '~> 1.5'
  gem 'pry', '>= 0.10'
  gem 'pry-byebug', platform: :ruby
end

group :development, :test do
  gem 'rubocop'
  gem 'yard', require: false
end
