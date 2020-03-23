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
    if type == 'domain_limit'
      limit <= usage
    elsif updated_at.strftime('%b %Y') != Time.now.utc.strftime('%b %Y')
      # If month changed monthly_send_limit need to be reset to 0
      update(usage: 0)
      false
    else
      limit <= usage
    end
  end
end
