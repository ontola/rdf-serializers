# frozen_string_literal: true

require_relative 'isolated_unit'

module ActiveModelSerializers
  RailsApplication = TestHelpers::Generation.make_basic_app do |app|
    app.configure do
      config.secret_key_base = 'abc123'
      config.active_support.test_order = :random
      config.action_controller.perform_caching = true
      config.action_controller.cache_store = :memory_store

      config.filter_parameters += [:password]
    end

    app.routes.default_url_options = { host: 'example.com' }
  end
end

Routes = ActionDispatch::Routing::RouteSet.new
Routes.draw do
  get ':controller(/:action(/:id))'
  get ':controller(/:action)'
end
ActionController::Base.send :include, Routes.url_helpers
ActionController::TestCase.class_eval do
  def setup
    @routes = Routes
  end
end
