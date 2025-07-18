class CreateUserHistories < ActiveRecord::Migration[Rails.version.to_s.split('.').first(2).join('.')]
  def change
    create_table :user_histories do |t|
      t.bigint :original_id
      t.string :name
      t.string :email
      t.text :internal_notes
      t.string :event
      t.datetime :history_created_at
      t.datetime :history_updated_at
    end
    add_index :user_histories, :original_id
  end
end
