class RemoveCredentialIdFromDomains < ActiveRecord::Migration[5.2]
  def change
    remove_column :domains, :credential_id, :integer
  end
end
