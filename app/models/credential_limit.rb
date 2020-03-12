# == Schema Information
#
# Table name: domains
#
#  id                     :integer          not null, primary key
#  credential_id          :integer
#  type                   :string
#  limit                  :integer
#  usage                  :integer          default 0


class CredentialLimit < ApplicationRecord
  belongs_to :credential

  TYPES = ['send_limit', 'domain_limit']

  validates :type, :inclusion => {:in => TYPES}
  validates_presence_of :limit, :usage
end
