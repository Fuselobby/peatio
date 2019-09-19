# encoding: UTF-8
# frozen_string_literal: true


class CryptoReport < ActiveRecord::Base
  scope :ordered, -> { order(id: :asc) }
  scope :ordered, -> { order(lang: :asc)}
end

# == Schema Information
# Schema version: 20190911130000
#
# Table name: crypto_reports
#
#  id      :integer          not null, primary key
#  crypto  :string(255)
#  context :text(65535)
#  lang    :string(255)
#
