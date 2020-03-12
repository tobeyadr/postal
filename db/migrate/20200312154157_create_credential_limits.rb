class CreateCredentialLimits < ActiveRecord::Migration[5.2]
  def change
    create_table :credential_limits do |t|
      t.belongs_to :credential
      t.string :type
      t.integer :limit
      t.integer :usage, default: 0

      t.timestamps
    end
  end
end
