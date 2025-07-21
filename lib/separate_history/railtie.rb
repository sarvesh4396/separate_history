# frozen_string_literal: true

require "rails/railtie"

module SeparateHistory
  class Railtie < ::Rails::Railtie
    initializer "separate_history.initialize" do
      ActiveSupport.on_load(:active_record) do
        extend SeparateHistory::Core
      end
    end
  end
end
