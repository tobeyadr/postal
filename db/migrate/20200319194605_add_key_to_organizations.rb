class AddKeyToOrganizations < ActiveRecord::Migration[5.2]
  def change
    add_column :organizations, :key, :string
    add_column :organizations, :last_used_at, :datetime
  end
end
