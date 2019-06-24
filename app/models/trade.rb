# encoding: UTF-8
# frozen_string_literal: true

class Trade < ActiveRecord::Base
  include BelongsToMarket
  extend Enumerize
  ZERO = '0.0'.to_d

  enumerize :trend, in: { up: 1, down: 0 }

  belongs_to :ask, class_name: 'OrderAsk', foreign_key: :ask_id, required: true
  belongs_to :bid, class_name: 'OrderBid', foreign_key: :bid_id, required: true
  belongs_to :ask_member, class_name: 'Member', foreign_key: :ask_member_id, required: true
  belongs_to :bid_member, class_name: 'Member', foreign_key: :bid_member_id, required: true

  validates :price, :volume, :funds, numericality: { greater_than_or_equal_to: 0.to_d }

  scope :h24, -> { where('created_at > ?', 24.hours.ago) }

  scope :ordered, -> { order(funds: :desc) }

  before_validation do
    self.ask_member_uid = ask_member.uid
    self.bid_member_uid = bid_member.uid
  end

  after_commit on: :create do
    EventAPI.notify ['market', market_id, 'trade_completed'].join('.'), \
      Serializers::EventAPI::TradeCompleted.call(self)
  end

  def trigger_campaigns(reward_user, campaign_type, source_user_id=nil, remark=nil)
    begin
      ActiveRecord::Base.transaction do
        uri = URI("http://campaign:8002/api/v1/campaigns/trigger_logs")
        req = Net::HTTP::Post.new(uri)
        campaign_log_data = {
          user_id: reward_user.uid,
          audience_type: 'All Users',
          campaign_type: campaign_type,
          source_type: self.class.name,
          source_id: id,
          source_user_id: source_user_id,
          remark: remark,
          amount: amount,
          fee: fee
        }
        req.set_form_data(campaign_log_data)

        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(req)
        end

        case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          @new_campaign_logs = JSON.parse(res.body)
          if @new_campaign_logs.present?
            @new_campaign_logs.each do |n|
              log_currency = Currency.find_by(id: n["receive_currency"], enabled: true)
              log_account = member.accounts.find_by(currency: log_currency)
              log_account.plus_funds(n["receive_amount"].to_d) if log_account

              Account.record_complete_operations(n["receive_amount"].to_d, log_currency, self)
            end
          end
        else
        end
      end
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace.join("\n")
    end
  end

  def trade_campaign
    trigger_campaigns(member, ["Deposit%#{currency_id}"].to_json)
  end

  def trade_referral_campaign
    referrer = Member.find_by(uid: member.referral_uid)
    remark = "The person you referred, #{member.email} has made a deposit!"
    trigger_campaigns(referrer, ["Deposit%#{currency_id}","Referral"].to_json, member.uid, remark) if referrer
  end

  class << self
    def latest_price(market)
      trade = with_market(market).order(id: :desc).limit(1).first
      trade ? trade.price : 0
    end
  end

  def side(member)
    return unless member

    self.ask_member_id == member.id ? 'ask' : 'bid'
  end

  def for_notify(member = nil)
    { id:     id,
      kind:   side(member),
      at:     created_at.to_i,
      price:  price.to_s  || ZERO,
      volume: volume.to_s || ZERO,
      ask_id: ask_id,
      bid_id: bid_id,
      market: market.id }
  end

  def for_global
    { tid:    id,
      type:   trend == 'down' ? 'sell' : 'buy',
      date:   created_at.to_i,
      price:  price.to_s || ZERO,
      amount: volume.to_s || ZERO }
  end

  def record_complete_operations!
    transaction do
      record_liability_debit!
      record_liability_credit!
      record_liability_transfer!
      record_revenues!
    end
  end

  private
  def record_liability_debit!
    ask_currency_outcome = volume
    bid_currency_outcome = funds

    # Debit locked fiat/crypto Liability account for member who created ask.
    Operations::Liability.debit!(
      amount:    ask_currency_outcome,
      currency:  ask.currency,
      reference: self,
      kind:      :locked,
      member_id: ask.member_id,
    )
    # Debit locked fiat/crypto Liability account for member who created bid.
    Operations::Liability.debit!(
      amount:    bid_currency_outcome,
      currency:  bid.currency,
      reference: self,
      kind:      :locked,
      member_id: bid.member_id,
    )
  end

  def record_liability_credit!
    # We multiply ask outcome by bid fee.
    # Fees are related to side bid or ask (not currency).
    ask_currency_income = volume - volume * bid.fee
    bid_currency_income = funds - funds * ask.fee

    # Credit main fiat/crypto Liability account for member who created ask.
    Operations::Liability.credit!(
      amount:    bid_currency_income,
      currency:  bid.currency,
      reference: self,
      kind:      :main,
      member_id: ask.member_id
    )

    # Credit main fiat/crypto Liability account for member who created bid.
    Operations::Liability.credit!(
      amount:    ask_currency_income,
      currency:  ask.currency,
      reference: self,
      kind:      :main,
      member_id: bid.member_id
    )
  end

  def record_liability_transfer!
    # Unlock unused funds.
    [bid, ask].each do |order|
      if order.volume.zero? && !order.locked.zero?
        Operations::Liability.transfer!(
          amount:    order.locked,
          currency:  order.currency,
          reference: self,
          from_kind: :locked,
          to_kind:   :main,
          member_id: order.member_id
        )
      end
    end
  end

  def record_revenues!
    ask_currency_fee = volume * bid.fee
    bid_currency_fee = funds * ask.fee

    # Credit main fiat/crypto Revenue account.
    Operations::Revenue.credit!(
      amount:    ask_currency_fee,
      currency:  ask.currency,
      reference: self,
      member_id: bid.member_id
    )

    # Credit main fiat/crypto Revenue account.
    Operations::Revenue.credit!(
      amount:    bid_currency_fee,
      currency:  bid.currency,
      reference: self,
      member_id: ask.member_id
    )
  end
end

# == Schema Information
# Schema version: 20190620022012
#
# Table name: trades
#
#  id             :integer          not null, primary key
#  price          :decimal(32, 16)  not null
#  volume         :decimal(32, 16)  not null
#  ask_id         :integer          not null
#  bid_id         :integer          not null
#  trend          :integer          not null
#  market_id      :string(20)       not null
#  ask_member_id  :integer          not null
#  bid_member_id  :integer          not null
#  funds          :decimal(32, 16)  not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  ask_member_uid :string(12)       not null
#  bid_member_uid :string(12)       not null
#
# Indexes
#
#  index_trades_on_ask_id                           (ask_id)
#  index_trades_on_ask_member_id_and_bid_member_id  (ask_member_id,bid_member_id)
#  index_trades_on_bid_id                           (bid_id)
#  index_trades_on_created_at                       (created_at)
#  index_trades_on_market_id_and_created_at         (market_id,created_at)
#
