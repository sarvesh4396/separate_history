class CreateUsers < ActiveRecord::Migration[Rails.version.to_s.split('.').first(2).join('.')]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.text :internal_notes
      t.timestamps
    end
  end
end
