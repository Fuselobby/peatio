module Admin
  class WalletsSummaryController < BaseController
  	before_action :get_balance, only: [:index]

    def index
        @hot_wallets = Wallet.active.where(kind: :hot)
        @fee_wallets = Wallet.active.where(kind: :fee)
    end

    def get_balance
    	return if params[:name].blank?

    	ActiveRecord::Base.transaction do
	    	wallet = Wallet.find_by(name: params[:name])
	    	wallet.current_balance = wallet.update_balance

	    	# updated_at wasn't updated if current_balance value remains unchanged therefore .touch is used
	    	wallet.touch
	    	wallet.save!
	    end
    end

  end
end
