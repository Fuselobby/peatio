class Activity < ActiveRecord::Base
  TOPICS = %w[blockchains currencies wallets markets].freeze
  RESULTS = %w[succeed failed].freeze

  belongs_to :user

  validates :user_ip, presence: true, allow_blank: false
  validates :user_agent, presence: true
  validates :topic, presence: true, inclusion: { in: TOPICS }
  validates :result, presence: true, inclusion: { in: RESULTS }

  # this method allows to use all the methods of ::Browser module (platofrm, modern?, version etc)
  def browser
    Browser.new(user_agent)
  end

private

  def readonly?
    !new_record?
  end
end

# == Schema Information
# Schema version: 20190501135106
#
# Table name: activities
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  user_ip    :string(255)      not null
#  user_agent :string(255)      not null
#  topic      :string(255)      not null
#  action     :string(255)      not null
#  result     :string(255)      not null
#  data       :text(65535)
#  created_at :datetime
#
