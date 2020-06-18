class AddIndexOnEmailToSuppressionLists < ActiveRecord::Migration[5.2]
  def change
    add_index :suppression_lists, :email
  end
end
