class AddListNameToLists < ActiveRecord::Migration[7.0]
  def change
    add_column :lists, :list_name, :string
  end
end
