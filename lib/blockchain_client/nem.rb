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
      normalize_address(tx['Destination'])
    end

    def from_address(tx)
      normalize_address(tx['Account'])
    end

    def load_balance!(address, currency)
    json_rpc('/status')
      .fetch('result')
      .fetch('account_data')
      .fetch('Balance')
      .to_d
      .yield_self { |amount| convert_from_base_unit(amount, currency) }
  rescue => e
    report_exception_to_screen(e)
    0.0
  end

    def build_transaction(tx:, currency:)
      {
        id: normalize_txid(tx.fetch('hash')),
        entries:       build_entries(tx, currency)
      }
    end

    def build_entries(tx, currency)
      [
        {
          amount:  convert_from_base_unit(tx.fetch('Amount'), currency)
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
      json_rpc(
        :ledger,
        [{
          "ledger_index": ledger_index || 'validated',
          "transactions": true,
          "expand": true
        }]
      ).dig('result', 'ledger', 'transactions') || []
    end

    def latest_block_number
      response = json_rpc('/chain/height').fetch('height')
    end

    def destination_tag_from(address)
      address =~ /\?dt=(\d*)\Z/
      $1.to_i
    end

    protected

    def connection
    end
    memoize :connection

    def json_rpc(path)
      uri = URI("#{@json_rpc_endpoint.to_s + path}")
      Rails.logger.debug { uri }
      req = Net::HTTP::Get.new(uri)
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      if res.body.present?

      end
    end

    def normalize_address(address)
      super(address.gsub(/\?dt=\d*\Z/, ''))
    end

    def valid_address?(address)
      /\Ar[0-9a-zA-Z]{33}(:?\?dt=[1-9]\d*)?\z/.match?(address)
    end
  end
end
