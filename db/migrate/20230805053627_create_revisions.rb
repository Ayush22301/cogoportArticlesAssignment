class CreateRevisions < ActiveRecord::Migration[7.0]
  def change
    create_table :revisions do |t|
      t.integer :article_id
      t.string :title
      t.text :content
      t.datetime :revision_time

      t.timestamps
    end
  end
end
