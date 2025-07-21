# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module SeparateHistory
  module Generators
    class MigrationGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)
      argument :name, type: :string, desc: "The name of the model to create history for"

      def create_migration_file
        migration_template "migration.rb.erb", "db/migrate/create_#{history_table_name}.rb"
      end

      private

      def history_table_name
        "#{name.underscore}_histories"
      end

      def history_class_name
        "#{name.camelize}History"
      end

      def original_class
        @original_class ||= name.camelize.constantize
      rescue NameError
        nil
      end

      def original_table_name
        if original_class
          original_class.table_name
        else
          name.underscore.pluralize
        end
      end

      def original_columns
        if original_class
          # Use actual model columns if class exists
          original_class.columns.reject do |c|
            [original_class.primary_key, "created_at", "updated_at"].include?(c.name)
          end
        else
          # Use common columns structure if model doesn't exist
          # This will be a basic structure for the migration
          []
        end
      end
    end
  end
end
