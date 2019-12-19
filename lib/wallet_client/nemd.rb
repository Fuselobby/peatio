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
      address: new_address['privateKey'],
      secret: new_address['address']
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

    def destination_tag_from(address)
      address =~ /\?dt=(\d*)\Z/
      $1.to_i
    end

    def create_withdrawal!(issuer, recipient, amount, _options = {})
      tx_blob = sign_transaction(issuer, recipient, amount)
      json_rpc(:submit, tx_blob).fetch('result').yield_self do |result|
        error_message = {
          message: result.fetch('engine_result_message'),
          status: result.fetch('engine_result')
        }

        # TODO: It returns provision results. Transaction may fail or success
        # than change status to opposite one before ledger is final.
        # Need to set special status and recheck this transaction status
        if result['engine_result'].to_s == 'tesSUCCESS' && result['status'].to_s == 'success'
          normalize_txid(result.fetch('tx_json').fetch('hash'))
        else
          raise Error, "XRP withdrawal from #{issuer.fetch(:address)} to #{recipient.fetch(:address)} failed. Message: #{error_message}."
        end
      end
    end

    def sign_transaction(issuer, recipient, amount)
      account_address = normalize_address(issuer.fetch(:address))
      destination_address = normalize_address(recipient.fetch(:address))
      destination_tag = destination_tag_from(recipient.fetch(:address))
      fee = calculate_current_fee
      amount_without_fee = convert_to_base_unit!(amount) - fee.to_i

      params = {
        secret: issuer.fetch(:secret),
        tx_json: {
          Account:            account_address,
          Amount:             amount_without_fee.to_s,
          Fee:                fee,
          Destination:        destination_address,
          DestinationTag:     destination_tag,
          TransactionType:    'Payment',
          LastLedgerSequence: latest_block_number + 4
        }
      }

      json_rpc(:sign, params).fetch('result').yield_self do |result|
        if result['status'].to_s == 'success'
          { tx_blob: result['tx_blob'] }
        else
          raise Error, "XRP sign transaction from #{account_address} to #{destination_address} failed: #{result}."
        end
      end
    end

    # Returns fee in drops that is enough to process transaction in current ledger
    def calculate_current_fee
      json_rpc(:fee, {}).fetch('result').yield_self do |result|
        result.dig('drops', 'open_ledger_fee')
      end
    end

    def load_balance!(address, currency)
      json_rpc(:account_info, [account: normalize_address(address), ledger_index: 'validated', strict: true])
        .fetch('result')
        .fetch('account_data')
        .fetch('Balance')
        .to_d
        .yield_self { |amount| convert_from_base_unit(amount) }
    rescue => e
      report_exception_to_screen(e)
      0.0
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

    def get_json_rpc(path)
      uri = URI("http://34.87.38.59:3000/api/v1/nems?key=#{ + path}")
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
