# encoding: UTF-8
# frozen_string_literal: true

require 'securerandom'

module WalletClient
  class Nemd < Base

    def initialize(*)
      Rails.logger.debug { 'init wallet client' }
      super
      @json_rpc_call_id  = 0
      @json_rpc_endpoint = URI.parse(wallet.uri)
    end

    def latest_block_number
      response = get_json_rpc('/chain/height')['height']
    end

    def create_address!(options = {})
    Rails.logger.debug { 'init wallet client' }
    new_address = get_json_rpc('/account/generate')
    {
      address: new_address['address'],
      secret: new_address['privateKey'],
      publickey: new_address['publicKey']
    }
    end

    def inspect_address!(address)
      {
        address:  normalize_address(address),
        is_valid: valid_address?(normalize_address(address))
      }
    end

    def valid_address?(address)
      true
    end

    def normalize_address(address)
      address
    end

    def create_withdrawal!(issuer, recipient, amount, _options = {})
      tx_blob = sign_transaction(issuer, recipient, amount)

      res = post_json_rpc('/transaction/prepare-announce', tx_blob.to_s)

      # TODO: It returns provision results. Transaction may fail or success
      # than change status to opposite one before ledger is final.
      # Need to set special status and recheck this transaction status
      if result['message'].to_s == 'SUCCESS'
        normalize_txid(result.fetch('transactionHash').fetch('data'))
      else
        raise Error, "NEM withdrawal from #{issuer.fetch(:address)} to #{recipient.fetch(:address)} failed. Message: #{error_message}."
      end
    end

    def sign_transaction(issuer, recipient, amount)
      account_address = normalize_address(issuer.fetch(:address))
      destination_address = normalize_address(recipient.fetch(:address))
      fee = calculate_current_fee(amount)
      amount_without_fee = convert_to_base_unit!(amount, issuer.fetch(:currency)) - fee.to_i

      {
        "transaction":
        {
            "timeStamp": Time.now.getutc.to_i,
            "amount": convert_to_base_unit!(amount_without_fee, issuer.fetch(:currency)),
            "fee": fee,
            "recipient": destination_address,
            "type": 257,
            "deadline": Time.now.getutc.to_i + 6000,
            "message":
            {
                "payload": "",
                "type": 1
            },
            "version": 1744830466,
            "signer": issuer.fetch(:publickey)
        },
        "privateKey": issuer.fetch(:secret)
      }
    end

    FEE_FACTOR = 0.05
    # Returns fee in drops that is enough to process transaction in current ledger
    def calculate_current_fee(amount)
      tmp = FEE_FACTOR * minimum_fee(amount / 1_000_000)
      #tmp += message_fee if @transaction.has_message?
      tmp * 1_000_000
    end

    def minimum_fee(base)
      tmp = [1, base / 10_000].max
      tmp > 25 ? 25 : tmp
    end

    def load_balance!(address, currency)
      get_json_rpc("/account/get?address=#{address}")
        .fetch('account')
        .fetch('balance')
        .to_d
        .yield_self { |amount| convert_from_base_unit(amount, currency) }
    rescue => e
      report_exception_to_screen(e)
      0.0
    end

    def convert_from_base_unit(value, currency)
      value.to_d / currency.base_factor
    end

    def convert_to_base_unit(value, currency)
      value.to_d * currency.base_factor
    end

    protected

    def connection
    end
    memoize :connection

    def get_json_rpc(path)
      uri = URI("#{@json_rpc_endpoint.to_s + path}")
      Rails.logger.debug { uri }
      req = Net::HTTP::Get.new(uri)
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      if res.body.present?
        result = JSON.parse(res.body)
      end
    end

    def post_json_rpc(path, params = {})
      uri = URI("#{@json_rpc_endpoint.to_s + path}")
      Rails.logger.debug { uri }
      req = Net::HTTP::Post.new(uri)
      req.add_field("Content-Type", "application/json")
      body_data = {
        "j_value": params
      }    
      req.body = body_data.to_json
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      if res.body.present?
        result = JSON.parse(res.body)
      end
    end
  end
end
