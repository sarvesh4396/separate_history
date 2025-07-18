# frozen_string_literal: true

require "separate_history/version"
require "separate_history/core"

module SeparateHistory
  class Error < StandardError; end

  @tracked_models = []

  def self.track_model(model)
    @tracked_models << model unless @tracked_models.include?(model)
  end

  def self.tracked_models
    @tracked_models.sort_by(&:name)
  end
end

require "separate_history/railtie" if defined?(Rails::Railtie)
