require 'test_helper'
require 'generators/separate_history/migration_generator'

class MigrationGeneratorTest < Rails::Generators::TestCase
  tests SeparateHistory::Generators::MigrationGenerator
  destination File.expand_path('../../../tmp/generators', __FILE__)
  setup :prepare_destination

  test "generator creates a migration for the user history table" do
    run_generator ["User"]
    assert_migration "db/migrate/create_user_histories.rb", /create_table :user_histories/
  end
end
