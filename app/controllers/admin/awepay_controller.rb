module Admin
  class AwepayController < BaseController

    def index
      puts "#{params}"

      @amount = params[:amount]
      @currency = params[:currency].upcase
      @postback_url = "https://uat2.speza.io/api/v1/applogic/callback/awepay_withdraw"

      @successurl = "#{request.referrer}"
      @failureurl = "#{request.referrer}"

      @uid = params[:uid]
      @rid = "#{params[:rid]}..#{@amount}#{@currency}"
    end

    def withdraw

    end
  end
end