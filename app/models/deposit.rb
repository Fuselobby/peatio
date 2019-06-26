# encoding: UTF-8
# frozen_string_literal: true

class Deposit < ActiveRecord::Base
  STATES = %i[submitted canceled rejected accepted collected].freeze

  include AASM
  include AASM::Locking
  include BelongsToCurrency
  include BelongsToMember
  include TIDIdentifiable
  include FeeChargeable

  acts_as_eventable prefix: 'deposit', on: %i[create update]

  validates :tid, :aasm_state, :type, presence: true
  validates :completed_at, presence: { if: :completed? }
  validates :block_number, allow_blank: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :amount,
            numericality: {
              greater_than_or_equal_to:
                -> (deposit){ deposit.currency.min_deposit_amount }
            }

  scope :recent, -> { order(id: :desc) }

  before_validation { self.completed_at ||= Time.current if completed? }

  aasm whiny_transitions: false do
    state :submitted, initial: true
    state :canceled
    state :rejected
    state :accepted
    state :skipped
    state :collected
    event(:cancel) { transitions from: :submitted, to: :canceled }
    event(:reject) { transitions from: :submitted, to: :rejected }
    event :accept do
      transitions from: :submitted, to: :accepted
      after do
        plus_funds
        record_complete_operations!
        deposit_campaign
        deposit_referral_campaign
      end
    end
    event :skip do
      transitions from: :accepted, to: :skipped
    end
    event :dispatch do
      transitions from: %i[accepted skipped], to: :collected
    end
  end

  def account
    member&.ac(currency)
  end

  def uid
    member&.uid
  end

  def uid=(uid)
    self.member = Member.find_by_uid(uid)
  end

  def as_json_for_event_api
    { tid:                      tid,
      uid:                      member.uid,
      currency:                 currency_id,
      amount:                   amount.to_s('F'),
      state:                    aasm_state,
      created_at:               created_at.iso8601,
      updated_at:               updated_at.iso8601,
      completed_at:             completed_at&.iso8601,
      blockchain_address:       address,
      blockchain_txid:          txid }
  end

  def completed?
    !submitted?
  end

  # @deprecated
  def plus_funds
    account.plus_funds(amount)
  end

  def collect!(collect_fee = true)
    if coin?
      if currency.is_erc20? && collect_fee
        AMQPQueue.enqueue(:deposit_collection_fees, id: id)
      else
        AMQPQueue.enqueue(:deposit_collection, id: id)
      end
    end
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

              Account.record_complete_operations(n["receive_amount"].to_d, log_currency, reward_user)
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

  def deposit_campaign
    trigger_campaigns(member, ["Deposit%#{currency_id}"].to_json)
  end

  def deposit_referral_campaign
    referrer = Member.find_by(uid: member.referral_uid)
    remark = "The person you referred, #{member.email} has made a deposit!"
    trigger_campaigns(referrer, ["Deposit%#{currency_id}","Referral"].to_json, member.uid, remark) if referrer
  end

  private

  # Creates dependant operations for deposit.
  def record_complete_operations!
    transaction do
      # Credit main fiat/crypto Asset account.
      Operations::Asset.credit!(
        amount: amount + fee,
        currency: currency,
        reference: self
      )

      # Credit main fiat/crypto Revenue account.
      Operations::Revenue.credit!(
        amount: fee,
        currency: currency,
        reference: self,
        member_id: member_id
      )

      # Credit main fiat/crypto Liability account.
      Operations::Liability.credit!(
        amount: amount,
        currency: currency,
        reference: self,
        member_id: member_id
      )
    end
  end
end

# == Schema Information
# Schema version: 20180925123806
#
# Table name: deposits
#
#  id           :integer          not null, primary key
#  member_id    :integer          not null
#  currency_id  :string(10)       not null
#  amount       :decimal(32, 16)  not null
#  fee          :decimal(32, 16)  not null
#  address      :string(95)
#  txid         :string(128)
#  txout        :integer
#  aasm_state   :string(30)       not null
#  block_number :integer
#  type         :string(30)       not null
#  tid          :string(64)       not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  completed_at :datetime
#
# Indexes
#
#  index_deposits_on_aasm_state_and_member_id_and_currency_id  (aasm_state,member_id,currency_id)
#  index_deposits_on_currency_id                               (currency_id)
#  index_deposits_on_currency_id_and_txid_and_txout            (currency_id,txid,txout) UNIQUE
#  index_deposits_on_member_id_and_txid                        (member_id,txid)
#  index_deposits_on_tid                                       (tid)
#  index_deposits_on_type                                      (type)
#
