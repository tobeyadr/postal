class AddTrackingFieldsToSuppressionLists < ActiveRecord::Migration[5.2]
  def change
    add_column :suppression_lists, :source, :string
    add_column :suppression_lists, :mail_from, :string
    add_column :suppression_lists, :reported_domain, :string
    add_column :suppression_lists, :source_ip, :string
    add_column :suppression_lists, :arrival_date, :datetime
    add_column :suppression_lists, :user_agent, :string
  end
end
