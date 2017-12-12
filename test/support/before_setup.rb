# frozen_string_literal: true

module Minitest
  class Test
    def before_setup
      ActionController::Base.cache_store.clear
    end
  end
end
