# frozen_string_literal: true

require "rails/generators"

module SeparateHistory
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "separate_history.rb", "config/initializers/separate_history.rb"
      end
    end
  end
end
