module Admin
  class AwepayController < BaseController
    # Fees 
    AWEPAY_MYR_FEE = 3.5
    AWEPAY_IDR_FEE = 3.5
    AWEPAY_THB_FEE = 3.5
    AWEPAY_VND_FEE = 3.5
    AWEPAY_KRW_FEE = 4

    def index
      @amount = value_after_fee(params[:amount], params[:currency])
      @currency = params[:currency].upcase
      @postback_url = "https://uat2.speza.io/api/v1/applogic/callback/awepay_withdraw"

      @successurl = "#{request.referrer}"
      @failureurl = "#{request.referrer}"

      @ref1 = params[:rid]
      @ref2 = "#{params[:uid]}..#{@amount}#{@currency}"
    end

    private
    def value_after_fee(value, currency)
      # default SID
      fee = 3.5

      case currency.upcase
      when 'MYR'
        fee = AWEPAY_MYR_FEE
      when 'THB'
        fee = AWEPAY_THB_FEE
      when 'IDR'
        fee = AWEPAY_IDR_FEE
      when 'VND'
        fee = AWEPAY_VND_FEE
      when 'KRW'
        fee = AWEPAY_KRW_FEE
      end

      fee_decimal = (100-fee)/100
      after_fee = (value.to_f * fee_decimal).round(2)

      after_fee
    end
  end
end