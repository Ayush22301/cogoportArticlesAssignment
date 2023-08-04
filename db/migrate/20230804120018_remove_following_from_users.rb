class RemoveFollowingFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :following, :string
  end
end
