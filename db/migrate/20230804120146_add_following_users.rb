class AddFollowingUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :following, :string, array: true, default: '[]'
  end
end
