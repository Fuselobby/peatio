# encoding: UTF-8
# frozen_string_literal: true

module BlockchainClient
  class Nem < Base
    def initialize(*)
      Rails.logger.debug { 'init blockchain client' }
      super
      @json_rpc_call_id  = 0
      @json_rpc_endpoint = URI.parse(blockchain.server)
      Rails.logger.debug { 'blockchain client url: ' + @json_rpc_endpoint.to_s }
    end

    def endpoint
      @json_rpc_endpoint
    end

    def to_address(tx)
      normalize_address(tx['recipient'])
    end

    def from_address(tx)
      normalize_address(tx['Account'])
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

    def build_transaction(tx:, currency:)
      newdata = get_json_rpc('/account/transfers/incoming?address=' + tx['recipient'])
      newdata['data'].each do |newx|
        if(tx['timeStamp'] == newx['transaction']['timeStamp'])
          return {id: newx['meta']['hash']['data'] ,entries: build_entries(tx, currency)}
        end
      end
    end

    def build_entries(tx, currency)
      [
        {
          amount:  convert_from_base_unit(tx['amount'], currency)
        }
      ]
    end

    def inspect_address!(address)
      {
        address:  normalize_address(address),
        is_valid: valid_address?(normalize_address(address))
      }
    end

    def calculate_confirmations(tx, ledger_index = nil)
      ledger_index ||= tx.fetch('ledger_index')
      latest_block_number - ledger_index
    end

    def fetch_transactions(ledger_index)
      post_json_rpc('/block/at/public', '{"height" : ' + ledger_index.to_s + '}')
    end

    def latest_block_number
      response = get_json_rpc('/chain/height')['height']
    end

    def destination_tag_from(address)
      address =~ /\?dt=(\d*)\Z/
      $1.to_i
    end

    def convert_from_base_unit(value, currency)
      value.to_d / currency.base_factor
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

    def normalize_address(address)
      address
    end

    def valid_address?(address)
      true
    end
  end
end
