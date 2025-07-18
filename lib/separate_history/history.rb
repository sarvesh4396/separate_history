require "active_support/concern"

module SeparateHistory
  module History
    extend ActiveSupport::Concern

    def manipulated?
      return false unless respond_to?(:history_created_at) && respond_to?(:history_updated_at)

      history_updated_at.to_i != history_created_at.to_i
    end
  end
end
