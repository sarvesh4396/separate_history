require "rails/generators"

module SeparateHistory
  module Generators
    class ScanGenerator < Rails::Generators::Base
      def scan_models
        Rails.application.eager_load!
        models = ActiveRecord::Base.descendants.select do |model|
          model.respond_to?(:separate_history_options)
        end

        if models.any?
          say "Models with has_separate_history:", :green
          models.each do |m|
            say "- #{m.name}", :cyan
            options = m.separate_history_options
            events = options[:events] || []
            if events.any?
              say "  Supported events: #{events.join(", ")}", :magenta
            else
              say "  Supported events: (none specified) [default is all]", :yellow
            end
          end
        else
          say "No models found with has_separate_history.", :yellow
        end
      end
    end
  end
end
