class AddIsDraftToArticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :isDraft, :boolean, default: false
  end
end
