class CreateSuppressionLists < ActiveRecord::Migration[5.2]
  def change
    create_table :suppression_lists do |t|
      t.string :email

      t.timestamps
    end
  end
end
