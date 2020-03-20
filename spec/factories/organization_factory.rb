# == Schema Information
#
# Table name: organizations
#
#  id                :integer          not null, primary key
#  uuid              :string(255)
#  name              :string(255)
#  permalink         :string(255)
#  time_zone         :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  ip_pool_id        :integer
#  owner_id          :integer
#  deleted_at        :datetime
#  suspended_at      :datetime
#  suspension_reason :string(255)
#  key               :string(255)
#  last_used_at      :datetime
#

FactoryBot.define do

  factory :organization do
    name { "Acme Inc" }
    sequence(:permalink) { |n| "org#{n}" }
    association :owner, :factory => :user
  end

end
