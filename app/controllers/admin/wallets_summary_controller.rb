module Admin
  class WalletsSummaryController < BaseController
    def index
      @hot_wallets = Wallet.active.where(kind: :hot).map(&:wallet_balance)
      @fee_wallets = Wallet.active.where(kind: :fee).map(&:wallet_balance)
    end

  end
end
