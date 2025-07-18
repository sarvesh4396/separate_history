# frozen_string_literal: true



ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('dummy/config/environment.rb', __dir__)
require 'rspec/rails'
require 'rails/generators'
require 'database_cleaner/active_record'
require 'fileutils'

# Load the gem
require 'separate_history'


RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include ActiveSupport::Testing::TimeHelpers

  # Run migrations before tests
  config.before(:suite) do
    Rails.application.load_tasks
    # Manually drop the database to avoid environment protection errors
    db_file = File.expand_path('dummy/db/test.sqlite3', __dir__)
    FileUtils.rm_f(db_file)

    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  # Clean up the database
  config.use_transactional_fixtures = false

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
