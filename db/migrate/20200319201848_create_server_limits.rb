class CreateServerLimits < ActiveRecord::Migration[5.2]
  def change
    create_table :server_limits do |t|
      t.integer :server_id
      t.string :type
      t.integer :limit
      t.integer :usage, default: 0

      t.timestamps
    end
  end
end
