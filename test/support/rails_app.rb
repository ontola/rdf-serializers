# frozen_string_literal: true

require_relative 'isolated_unit'

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
