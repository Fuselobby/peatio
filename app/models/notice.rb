# encoding: UTF-8
# frozen_string_literal: true



class Notice < ActiveRecord::Base
  scope :ordered, -> { order(id: :asc) }
  scope :enabled, -> { where(enabled: true) }

  validates :from_date, :to_date, presence: true
end

# == Schema Information
# Schema version: 20190815105500
#
# Table name: notices
#
#  id           :integer          not null, primary key
#  notice_title :string(255)      not null
#  description  :text(65535)
#  enabled      :boolean          default(TRUE), not null
#  from_date    :datetime
#  to_date      :datetime
#  created_at   :datetime         not null
#
