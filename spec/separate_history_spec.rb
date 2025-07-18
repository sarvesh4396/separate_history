# frozen_string_literal: true

RSpec.describe SeparateHistory do
  describe "basic history tracking" do
    let!(:user) { User.create!(name: "John Doe", email: "john.doe@example.com") }

    it "creates a history record on create" do
      expect(UserHistory.count).to eq(1)
      history = UserHistory.last
      expect(history.event).to eq("create")
      expect(history.name).to eq("John Doe")
    end

    it "creates a history record on update" do
      user.update!(name: "Jane Doe")
      expect(UserHistory.count).to eq(2)
      history = UserHistory.last
      expect(history.event).to eq("update")
      expect(history.name).to eq("Jane Doe")
    end

    it "creates a history record on destroy" do
      user.destroy
      expect(UserHistory.count).to eq(2) # create and destroy
      history = UserHistory.last
      expect(history.event).to eq("destroy")
    end

    it "creates a snapshot" do
      user.snapshot_history
      expect(UserHistory.count).to eq(2)
      history = UserHistory.last
      expect(history.event).to eq("snapshot")
    end
  end

  describe "associations" do
    let(:user) { User.create!(name: "Test User") }

    it "associates history records with the user" do
      expect(user.user_histories.count).to eq(1)
    end

    it "associates the user with the history record" do
      history = user.user_histories.first
      expect(history.user).to eq(user)
    end
  end

  describe "history?" do
    it "returns false for a new record" do
      user = User.new(name: "Newbie")
      expect(user.history?).to be false
    end

    it "returns true for a persisted record" do
      user = User.create!(name: "Persisted")
      expect(user.history?).to be true
    end
  end

  describe "selective tracking" do
    context "with :only option" do
      before do
        class Project < ApplicationRecord
          self.table_name = "users"
          has_separate_history only: [:name], history_class_name: "UserHistory"
        end
      end

      after { Object.send(:remove_const, :Project) }

      it "tracks only specified attributes" do
        project = Project.create!(name: "Project A", email: "proj.a@example.com")
        project.update!(name: "Project B", email: "proj.b@example.com")
        history = UserHistory.last
        expect(history.name).to eq("Project B")
        expect(history.email).to be_nil
      end
    end

    context "with :except option" do
      before do
        class Task < ApplicationRecord
          self.table_name = "users"
          has_separate_history except: [:email], history_class_name: "UserHistory"
        end
      end

      # after { Object.send(:remove_const, :Task) }

      it "tracks all but the excluded attributes" do
        task = Task.create!(name: "Task 1", email: "task.one@example.com")
        task.update!(name: "Task 2", email: "task.two@example.com")
        history = UserHistory.last
        expect(history.name).to eq("Task 2")
        expect(history.email).to be_nil
      end
    end

    # context 'with track_changes: true option' do
    #   before do
    #     class Product < ApplicationRecord
    #       self.table_name = 'users'
    #       has_separate_history track_changes: true, history_class_name: 'UserHistory'
    #     end
    #   end

    #   after { Object.send(:remove_const, :Product) }

    #   it 'records only the changed attributes on update' do
    #     product = Product.create!(name: 'Initial Name', email: 'initial@example.com')
    #     product.update!(name: 'Updated Name')

    #     history_record = product.user_histories.last
    #     expect(history_record.event).to eq('update')
    #     expect(history_record.name).to eq('Updated Name')
    #     expect(history_record.email).to be_nil
    #   end
    # end
  end

  describe ".history_for" do
    let!(:user) do
      travel_to 3.days.ago do
        User.create!(name: "Initial Name")
      end
    end

    before do
      travel_to 2.days.ago do
        user.update!(name: "Updated Name")
      end
      travel_to 1.day.ago do
        user.update!(name: "Final Name")
      end
    end

    it "returns the state at a specific point in time" do
      # Check state before any updates
      snapshot = User.history_for(user.id, 2.days.ago - 1.second)
      expect(snapshot.name).to eq("Initial Name")

      # Check state after the first update
      snapshot = User.history_for(user.id, 1.day.ago - 1.second)
      expect(snapshot.name).to eq("Updated Name")

      # Check state after the final update
      snapshot = User.history_for(user.id, Time.current)
      expect(snapshot.name).to eq("Final Name")
    end

    it "returns the earliest record if the time is exact" do
      # The creation time
      snapshot = User.history_for(user.id, user.created_at)
      expect(snapshot.name).to eq("Initial Name")
      expect(snapshot.event).to eq("create")
    end

    it "returns nil if no history exists before the given time" do
      snapshot = User.history_for(user.id, 4.days.ago)
      expect(snapshot).to be_nil
    end
  end

  describe "history instance" do
    describe "#manipulated?" do
      let!(:user) { User.create!(name: "John Doe") }
      let(:history) { user.user_histories.first }

      it "returns false when not manipulated" do
        expect(history.manipulated?).to be false
      end

      it "returns true when manipulated" do
        # Manually update to simulate manipulation, as the gem does not do this.
        history.update!(history_updated_at: Time.now + 1.hour)
        expect(history.manipulated?).to be true
      end
    end

    describe "seperate_histories association" do
      let!(:user) { User.create!(name: "John Doe") }
      let(:history) { user.user_histories.first }

      it "returns the history records for the instance" do
        expect(user.user_histories).to eq([history])
        expect(user.separate_histories).to eq([history])
      end

    end

    # context 'with track_changes option' do
    #   before do
    #     class Product < ActiveRecord::Base
    #       self.table_name = 'users'
    #       has_separate_history track_changes: true, history_class_name: 'UserHistory'
    #     end
    #   end

    #   after do
    #     Object.send(:remove_const, :Product)
    #   end

    #   it 'records only the changed attributes on update' do
    #     product = Product.create!(name: 'Initial Name', email: 'initial@example.com')
    #     product.update!(name: 'Updated Name')

    #     history_record = product.user_histories.last
    #     expect(history_record.event).to eq('update')
    #     expect(history_record.name).to eq('Updated Name')
    #     expect(history_record.email).to be_nil
    #   end
    # end
  end

  # Additional tests for SeparateHistory::Model instance methods
  describe "SeparateHistory::Model instance methods" do
    let!(:user) do
      travel_to 3.days.ago do
        User.create!(name: "John Doe", email: "john@example.com")
      end
    end

    describe "#snapshot_history" do
      it "creates a snapshot history record" do
        expect { user.snapshot_history }.to change { UserHistory.count }.by(1)
        expect(UserHistory.last.event).to eq("snapshot")
      end
    end

    describe "#history?" do
      it "returns true if history exists" do
        expect(user.history?).to be true
      end

      it "returns false if no history exists" do
        new_user = User.new(name: "No History")
        expect(new_user.history?).to be false
      end
    end

    describe "#history_as_of" do
      before do
        travel_to 1.day.ago do
          user.update!(name: "Yesterday")
        end
      end

      it "returns the correct snapshot for a given time" do
        # Create a snapshot at the current time
        user.snapshot_history
        
        # Get history for 2 days ago (should be the original create event)
        snapshot = user.history_as_of(2.days.ago)
        expect(snapshot).to be_present
        expect(snapshot.name).to eq("John Doe")
        
        # Get history for 12 hours ago (should be the update to "Yesterday")
        snapshot = user.history_as_of(12.hours.ago)
        expect(snapshot).to be_present
        expect(snapshot.name).to eq("Yesterday")
      end
      
      it "returns nil if no history exists before the given time" do
        snapshot = user.history_as_of(1.year.ago)
        expect(snapshot).to be_nil
      end
    end

    describe "#all_history" do
      before do
        user.update!(name: "Jane")
        user.update!(name: "Janet")
      end

      it "returns all history records for the instance" do
        expect(user.all_history.map(&:name)).to include("John Doe", "Jane", "Janet")
      end
    end

    describe "#latest_history" do
      before do
        user.update!(name: "Latest")
      end

      it "returns the most recent history record" do
        expect(user.latest_history.name).to eq("Latest")
      end
    end

    describe "#clear_history" do
      before do
        user.update!(name: "To be cleared")
      end

      it "removes all history records when force: true" do
        expect { user.clear_history(force: true) }.to change { UserHistory.where(original_id: user.id).count }.to(0)
      end

      it "raises error if force is not true" do
        expect { user.clear_history(force: false) }.to raise_error(ArgumentError)
      end
    end
  end

  # Add this at the end of the file, after all other test cases
  describe "SeparateHistory with track_changes" do
    before(:all) do
      class TrackedProduct < ActiveRecord::Base
        self.table_name = 'users'  # Using users table for testing
        has_separate_history track_changes: true, history_class_name: 'UserHistory'
      end
    end

    after(:all) do
      Object.send(:remove_const, :TrackedProduct) if defined?(TrackedProduct)
    end

    it 'records only the changed attributes on update when track_changes is true' do
      # Create initial record
      product = TrackedProduct.create!(
        name: 'Initial Product',
        email: 'initial@example.com',
        created_at: Time.current,
        updated_at: Time.current
      )

      # Update only the name
      product.update!(name: 'Updated Product')

      # Get the history record
      history_record = product.user_histories.last

      # Verify the history record
      expect(history_record.event).to eq('update')
      expect(history_record.name).to eq('Updated Product')
      expect(history_record.email).to be_nil  # Should be nil as it wasn't changed
      expect(history_record.original_id).to eq(product.id)
    end
  end
end
