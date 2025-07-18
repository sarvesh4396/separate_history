require "active_support/concern"
require "separate_history/model"
require "separate_history/history"
module SeparateHistory
  module Core
    extend ActiveSupport::Concern

    def has_separate_history(options = {})
      raise ArgumentError, "has_separate_history can not be called on an abstract class" if abstract_class?
      raise ArgumentError, "Options :only and :except can not be used together" if options[:only] && options[:except]

      valid_options = %i[only except history_class_name events track_changes]
      invalid_options = options.keys - valid_options
      raise ArgumentError, "Invalid options: #{invalid_options.join(", ")}" if invalid_options.any?
      options[:track_changes] = false if options[:track_changes].nil?
      unless options[:track_changes].is_a?(TrueClass) || options[:track_changes].is_a?(FalseClass)
        raise ArgumentError, "track_changes must be true or false"
      end

      supported_events = %i[create update destroy]
      if options[:events]
        events = Array(options[:events])
        invalid_events = events - supported_events
        raise ArgumentError, "Invalid events: #{invalid_events.join(", ")}" if invalid_events.any?
      end

      cattr_accessor :separate_history_options
      self.separate_history_options = options

      class << self
        # Returns the history class (e.g., UserHistory for User)
        def history_class
          history_class_name = separate_history_options.fetch(:history_class_name, "#{name}History")
          history_class_name.safe_constantize
        end

        # Returns the snapshot of the record as it was at or before the given timestamp
        def history_for(id, timestamp = Time.current)
          history_class.where(original_id: id)
                       .where("history_updated_at <= ?", timestamp)
                       .order(history_updated_at: :desc, id: :desc)
                       .first
        end

        # Alias for readability: get the state of a record as of a point in time
        def history_as_of(id, timestamp)
          history_for(id, timestamp)
        end

        # Returns true if any history exists for the given record ID
        def history_exists_for?(id)
          history_class.where(original_id: id).exists?
        end

        # Returns all history records for the given record ID, ordered by update time
        def all_history_for(id)
          history_class.where(original_id: id)
                       .order(history_updated_at: :asc, id: :asc)
        end

        # Returns the most recent history record for the given record ID
        def latest_history_for(id)
          history_class.where(original_id: id)
                       .order(history_updated_at: :desc, id: :desc)
                       .first
        end

        # Deletes all history for the given record ID.
        # Requires force: true to prevent accidental destruction.
        def clear_history_for(id, force:)
          raise ArgumentError, "Force must be true to clear history." unless force

          history_class.where(original_id: id).delete_all
        end

        # clear all history for all records of this model
        def clear_all_history(force:)
          raise ArgumentError, "Force must be true to clear all history." unless force

          history_class.delete_all
        end
      end

      history_class_name = options.fetch(:history_class_name, "#{name}History")
      history_table_name = history_class_name.tableize
      association_name   = name.demodulize.underscore.to_sym

      # Main association
      # Main association for accessing all history records
      has_many history_table_name.to_sym,
               class_name: history_class_name,
               foreign_key: :original_id,
               inverse_of: association_name

      # Alias association for convenience (points to the same records)
      alias_method :separate_histories, history_table_name.to_sym

      history_class = history_class_name.safe_constantize
      if history_class
        # Set up the belongs_to association on the history class
        unless history_class.reflect_on_association(association_name)
          history_class.belongs_to association_name,
                                   class_name: name,
                                   foreign_key: :original_id,
                                   inverse_of: history_table_name.to_sym,
                                   optional: true
        end

        history_class.include SeparateHistory::History
      end

      # Model-level events support
      events = Array(options[:events] || supported_events)
      events.each do |event|
        next unless supported_events.include?(event)

        after_commit :"record_history_#{event}", on: event
      end

      include SeparateHistory::Model
      SeparateHistory.track_model(self)
    end
  end
end
