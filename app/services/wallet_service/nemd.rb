# encoding: UTF-8
# frozen_string_literal: true

module WalletService
  class Nemd < Base
    def create_address(options = {})
      client.create_address!(options)
    end

    def collect_deposit!(deposit, options={})
      pa = deposit.account.payment_address
      spread_hash = spread_deposit(deposit)
      spread_hash.map do |address, amount|
        client.create_withdrawal!(
          { address: pa.address, secret: pa.secret, publickey: pa.details['publickey'], currency: deposit.currency },
          { address: address },
          amount,
          options
        )
      end
    end

    def build_withdrawal!(withdraw, options = {})
      client.create_withdrawal!(
        { address: wallet.address, secret: wallet.secret, publickey: wallet.settings['publickey'], currency: wallet.currency },
        { address: withdraw.rid },
        withdraw.amount,
        options
      )
    end

    def load_balance(address, currency)
      client.load_balance!(address, currency)
    end
  end
end
