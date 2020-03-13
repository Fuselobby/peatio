module Worker
    class BinanceWTrading
        def process(payload)

            matched_item = ::BinanceTrading.find_by(tx_id: payload["tx_id"], status: "matched".downcase)

            if matched_item.present?
                timestamp = Time.now.utc.to_i * 1000

                body = {
                    symbol: matched_item.market.upcase, #Base_Quote #@market.upcase,
                    side: matched_item.side.upcase, #BUY | SELL
                    type: 'MARKET',
                    quantity: matched_item.ori_volume.to_f,
                    newClientOrderId: matched_item.tx_id, # A unique id for the order. Automatically generated if not sent.
                    newOrderRespType: 'RESULT',
                    recvWindow: '5000',
                    timestamp: timestamp
                }

                request = ::Binance::BinanceShareFunction.get_api_with_header.post("/api/v3/order") do |req|
                    req.headers['X-MBX-APIKEY'] = ::Binance::BinanceShareFunction.get_apikey
                    req.body = URI.encode_www_form(::Binance::BinanceShareFunction.generate_body(body))
                end

                if request.env.status != 200
                    ::Binance::BinanceShareFunction.fatal(::Binance::BinanceShareFunction.build_error(request))
                else
                    response = JSON.parse(request.body)

                    matched_item.order_id = response["orderId"]
                    matched_item.tx_datetime = Time.at(response["transactTime"]/1000).to_datetime.to_formatted_s(:db)
                    matched_item.price = response["price"]
                    matched_item.ori_qty = response["origQty"]
                    matched_item.exe_qty = response["executedQty"]
                    matched_item.cum_qty = response["cummulativeQuoteQty"]
                    matched_item.status = response["status"]
                    matched_item.time_in_force = response["timeInForce"]
                    matched_item.trading_type = response["type"]
                    matched_item.side = response["side"]

                    matched_item.save
                    
                end
            end
        end
    end
end

