# == Schema Information
#
# Table name: server_limits
#
#  id         :bigint(8)        not null, primary key
#  server_id  :integer
#  type       :string(255)
#  limit      :integer
#  usage      :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ServerLimit < ApplicationRecord
  belongs_to :server

  TYPES = ['monthly_send_limit', 'domain_limit']

  validates :type, :inclusion => {:in => TYPES}
  validates_presence_of :limit, :usage

  def limit_exhausted?
    limit <= usage
  end
end
