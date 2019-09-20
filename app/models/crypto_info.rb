# encoding: UTF-8
# frozen_string_literal: true

class CryptoInfo < ActiveRecord::Base
  scope :ordered, -> { order(id: :asc) }
  # scope :ordered, -> { order(crypto: :asc) }

end

# == Schema Information
# Schema version: 20190911130000
#
# Table name: crypto_infos
#
#  id      :integer          not null, primary key
#  crypto  :string(255)
#  context :text(65535)
#
