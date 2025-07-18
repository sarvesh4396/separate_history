require "active_support/concern"

module SeparateHistory
  module Model
    extend ActiveSupport::Concern

    # Manually create a history snapshot for this record
    def snapshot_history
      _create_history_record("snapshot")
    end

    # Check if any history exists for this instance
    def history?
      self.class.history_class.where(original_id: id).exists?
    end

    # Get the snapshot of this record at or before the given timestamp
    def history_as_of(timestamp)
      self.class.history_for(id, timestamp)
    end

    # Get all historical versions of this record
    def all_history
      self.class.all_history_for(id)
    end

    # Get the latest snapshot of this record
    def latest_history
      self.class.latest_history_for(id)
    end

    # Delete this record’s history (requires force: true)
    def clear_history(force:)
      raise ArgumentError, "Force must be true to clear history." unless force

      self.class.history_class.where(original_id: id).delete_all
    end

    private

    def record_history_create
      _create_history_record("create")
    end

    def record_history_update
      _create_history_record("update") if _tracked_attributes_changed?
    end

    def record_history_destroy
      _create_history_record("destroy")
    end

    def _create_history_record(event)
      attrs = attributes_for_history(event)
      history_class.create!(attrs)
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message.match?(/Table '.*' doesn't exist/)

      raise "History table `#{history_class.table_name}` is missing. " \
            "Run `rails g separate_history:model #{self.class.name}` to create it."
    end

    def attributes_for_history(event)
      options = self.class.separate_history_options

      attrs = if options[:track_changes] && event == 'update'
                saved_changes.transform_values(&:last).with_indifferent_access
              else
                attributes.dup
              end
      
      # For track_changes, we need to ensure original_id is set properly
      # since saved_changes doesn't include the id attribute
      if options[:track_changes] && event == 'update'
        attrs["original_id"] = id
      else
        attrs["original_id"] = attrs.delete("id")
      end
      attrs["event"] = event.to_s

      # attrs["history_created_at"] = attrs.delete("created_at") if attrs.key?("created_at")
      # attrs["history_updated_at"] = attrs.delete("updated_at") if attrs.key?("updated_at")

      attrs["history_created_at"] = Time.now
      attrs["history_updated_at"] = Time.now

      if options[:only]
        allowed_keys = options[:only].map(&:to_s) + %w[original_id event history_created_at history_updated_at]
        attrs.slice!(*allowed_keys)
      elsif options[:except]
        options[:except].each { |key| attrs.delete(key.to_s) }
      end

      # remove columns that are not present in the history table
      history_columns = history_class.column_names
      attrs.select! { |key, _| history_columns.include?(key) }
      attrs
    end

    def _tracked_attributes_changed?
      # If track_changes is true, we always want to record the update
      # because the point is to track only the changed attributes
      return true if self.class.separate_history_options[:track_changes]
      
      if self.class.separate_history_options[:only].nil? && self.class.separate_history_options[:except].nil?
        return true
      end

      tracked_columns = if self.class.separate_history_options[:only]
                          self.class.separate_history_options[:only].map(&:to_s)
                        else
                          self.class.column_names - self.class.separate_history_options[:except].map(&:to_s)
                        end
      (saved_changes.keys & tracked_columns).any?
    end

    def history_class
      history_class_name = self.class.separate_history_options.fetch(:history_class_name, "#{self.class.name}History")
      @history_class ||= history_class_name.constantize
    end
  end
end
