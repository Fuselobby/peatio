class BinancePriceTicker < ActiveRecord::Base
    def self.get_market_price(symbol)
        reqbody = ""

        if !symbol.blank?
            reqbody = Binance::BinanceShareFunction.create_query( { symbol: symbol.upcase } )
        end

        if !reqbody.blank?
            request = Binance::BinanceShareFunction.get_api.get('/api/v3/ticker/price' + "?" + reqbody.chomp('&'))
        else                 
            request = Binance::BinanceShareFunction.get_api.get('/api/v3/ticker/price' + "?")
        end

        if request.env.status != 200
            Binance::BinanceShareFunction.fatal(Binance::BinanceShareFunction.build_error(request))
            return
        else
            response = JSON.parse(request.body)

            binancepriceticker = BinancePriceTicker.find_by(symbol: response['symbol'])
            if binancepriceticker.present?
                binancepriceticker.price = response['price']
            else
                binancepriceticker = BinancePriceTicker.new(symbol: response['symbol'], price: response['price'])
            end
    
            binancepriceticker.save!

            return binancepriceticker
        end
    end
end

# == Schema Information
# Schema version: 20200219033915
#
# Table name: binance_price_tickers
#
#  id         :integer          not null, primary key
#  symbol     :string(255)      not null
#  price      :decimal(32, 16)  default(0.0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
