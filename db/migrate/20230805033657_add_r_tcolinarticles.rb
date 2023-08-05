class AddRTcolinarticles < ActiveRecord::Migration[7.0]
  def change
    add_column :articles, :read_time, :float
  end
end
