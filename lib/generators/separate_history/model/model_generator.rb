# frozen_string_literal: true

require "rails/generators/active_record"

module SeparateHistory
  module Generators
    class ModelGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)
      argument :name, type: :string

      def create_migration_file
        # if exists history class, skip migration and tell run seperate_histaor:migration name
        if Object.const_defined?(history_class_name)
          say_status :skipped, "History class #{history_class_name} already exists. "\
            "Run `rails g separate_history:migration #{name}` to create a migration for it.", :yellow
          nil
        else
          migration_template "migration.rb.erb", "db/migrate/create_#{file_name}_history.rb"
          say_status :created, "Migration for #{history_class_name} created successfully.", :green
        end
      end

      def create_model_file
        @original_class = name.classify.constantize
        template "model.rb.erb", "app/models/#{file_name}_history.rb"
      end

      private

      def file_name
        name.underscore
      end

      def history_class_name
        "#{name}History"
      end
    end
  end
end
