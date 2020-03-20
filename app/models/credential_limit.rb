# == Schema Information
#
# Table name: credential_limits
#
#  id            :integer          not null, primary key
#  credential_id :integer
#  type          :string(255)
#  limit         :integer
#  usage         :integer          default(0)
#  created_at    :datetime
#  updated_at    :datetime
#

class CredentialLimit < ApplicationRecord
  belongs_to :credential

  TYPES = ['send_limit', 'domain_limit']

  validates :type, :inclusion => {:in => TYPES}
  validates_presence_of :limit, :usage

  def limit_exhausted?
    limit <= usage
  end
end
