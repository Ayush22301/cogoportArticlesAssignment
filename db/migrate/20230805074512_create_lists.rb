class CreateLists < ActiveRecord::Migration[7.0]
  def change
    create_table :lists do |t|
      t.integer :user_id
      t.text :arrayids

      t.timestamps
    end
  end
end
