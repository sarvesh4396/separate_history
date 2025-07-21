# frozen_string_literal: true

require_relative "lib/separate_history/version"

Gem::Specification.new do |spec|
  spec.name = "separate_history"
  spec.version = SeparateHistory::VERSION
  spec.authors = ["Sarvesh Dwivedi"]
  spec.email = ["heysarvesh@pm.me"]

  spec.summary = "Automatic versioning for ActiveRecord models in separate tables."
  spec.description = "separate_history is a Ruby on Rails gem that adds automatic versioning to ActiveRecord models. It stores versioned records in dedicated _histories tables for each model."
  spec.homepage = "https://github.com/sarvesh4396/separate_history"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/sarvesh4396/separate_history/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/sarvesh4396/separate_history/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.each_line("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_development_dependency "appraisal", "~> 2.4"
  spec.add_development_dependency "database_cleaner-active_record", "~> 2.0"
  spec.add_development_dependency "rails", "~> 7.0"
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rails-omakase", "~> 1.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
