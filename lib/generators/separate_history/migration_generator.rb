require "rails/generators"
require "rails/generators/active_record"

module SeparateHistory
  module Generators
    class MigrationGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path('templates', __dir__)
      argument :name, type: :string, desc: 'The name of the model to create history for'

      def create_migration_file
        migration_template 'migration.rb.erb', "db/migrate/create_#{history_class_name.underscore}.rb"
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
      end

      def original_table_name
        original_class.table_name
      end

      def original_columns
        @original_columns = original_class.columns.reject do |c|
          [original_class.primary_key, "created_at", "updated_at"].include?(c.name)
        end
      end
    end
  end
end
