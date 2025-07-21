# frozen_string_literal: true

require "rails/generators/active_record"

module SeparateHistory
  module Generators
    class SyncGenerator < ActiveRecord::Generators::Base
      source_root File.expand_path("templates", __dir__)
      argument :name, type: :string

      def create_migration_file
        @model_class = name.classify.constantize
        @history_table_name = "#{name.underscore}_histories"

        check_for_mismatched_columns

        @missing_columns = find_missing_columns

        if @missing_columns.any?
          migration_template "migration.rb.erb", "db/migrate/sync_#{file_name}_history.rb"
        else
          say_status :skipped, "No new columns to add for #{name}", :green
        end
      end

      private

      def check_for_mismatched_columns
        original_cols = @model_class.columns.index_by(&:name)
        history_cols = ActiveRecord::Base.connection.columns(@history_table_name).index_by(&:name)

        mismatched = []
        (original_cols.keys & history_cols.keys).each do |col|
          if original_cols[col].type != history_cols[col].type
            mismatched << "- '#{col}' is '#{original_cols[col].type}' in original table but '#{history_cols[col].type}' in history table."
          end
        end

        return unless mismatched.any?

        say_status :warning, "Mismatched column types detected for #{name}:", :yellow
        mismatched.each { |m| say m, :yellow }
      end

      def find_missing_columns
        original_columns = @model_class.column_names
        history_columns = ActiveRecord::Base.connection.columns(@history_table_name).map(&:name)

        (original_columns - history_columns) - ["id"]
      end

      def file_name
        name.underscore
      end
    end
  end
end
