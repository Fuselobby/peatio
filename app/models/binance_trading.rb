class BinanceTrading < ActiveRecord::Base
    require 'uri'

    has_one   :member,    dependent: :destroy

    validates :tx_id,  presence: true, uniqueness: true

    before_validation :assign_tx_id

    scope :status_new_or_partially_filled, -> { where(status: ["new".downcase, "partially_filled".downcase]) }  

    private
    def assign_tx_id
        return unless tx_id.blank?

        loop do
        self.tx_id = random_tx_id
        break unless BinanceTrading.where(tx_id: tx_id).any?
        end
    end

    def random_tx_id
        "TX#{SecureRandom.hex(5).upcase}"
    end
end

# == Schema Information
# Schema version: 20200219033915
#
# Table name: binance_tradings
#
#  id            :integer          not null, primary key
#  market        :string(10)       not null
#  trade_id      :integer          not null
#  user_uid      :string(12)       not null
#  order_id      :integer
#  tx_id         :string(12)       not null
#  tx_datetime   :datetime         not null
#  ori_price     :decimal(32, 16)  default(0.0), not null
#  price         :decimal(32, 16)  default(0.0), not null
#  ori_volume    :decimal(32, 16)  default(0.0), not null
#  ori_qty       :decimal(32, 16)  default(0.0), not null
#  exe_qty       :decimal(32, 16)  default(0.0), not null
#  cum_qty       :decimal(32, 16)  default(0.0), not null
#  status        :string(30)       default("matched"), not null
#  time_in_force :string(10)
#  trading_type  :string(30)       default("market")
#  side          :string(30)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
