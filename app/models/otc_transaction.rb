class OtcTransaction < ActiveRecord::Base
  belongs_to :member

  after_create :record_complete_operations

  def record_complete_operations
    #TODO: accounting purpose
    case otc_type
    when 'off-chain'
      # revenue = volume*exchange_fee + network_fee
    when 'on-chain'
      # revenue = volume*exchange_fee
    else
    end

  end

end

# == Schema Information
# Schema version: 20190712060736
#
# Table name: otc_transactions
#
#  id                  :integer          not null, primary key
#  member_id           :integer
#  currency_pay        :string(255)      not null
#  currency_get        :string(255)      not null
#  destination_address :string(255)      not null
#  price               :decimal(32, 16)  default(0.0), not null
#  exchange_fee        :decimal(17, 16)  default(0.0), not null
#  network_fee         :decimal(17, 16)  default(0.0), not null
#  amount_pay          :decimal(32, 16)  default(0.0), not null
#  amount_get          :decimal(32, 16)  default(0.0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  volume              :decimal(32, 16)  default(0.0), not null
#  otc_type            :string(255)      not null
#
# Indexes
#
#  index_otc_transactions_on_member_id  (member_id)
#
# Foreign Keys
#
#  fk_rails_0229b29078  (member_id => members.id)
#
