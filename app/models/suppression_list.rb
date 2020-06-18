# == Schema Information
#
# Table name: suppression_lists
#
#  id              :bigint(8)        not null, primary key
#  email           :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  source          :string(255)
#  mail_from       :string(255)
#  reported_domain :string(255)
#  source_ip       :string(255)
#  arrival_date    :datetime
#  user_agent      :string(255)
#

class SuppressionList < ApplicationRecord
  validates_uniqueness_of :email, case_sensitive: false
  validates_presence_of :email
end
