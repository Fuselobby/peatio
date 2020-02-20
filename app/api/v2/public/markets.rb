# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Public
      class Markets < Grape::API

        class OrderBook < Struct.new(:asks, :bids); end

        resource :markets do
          desc 'Get all available markets.',
            is_array: true,
            success: API::V2::Entities::Market
          get "/" do
            present ::Market.enabled.ordered, with: API::V2::Entities::Market
          end

          desc 'Get top performing markets.',
            is_array: true,
            success: API::V2::Entities::Market
          params do
            optional :limit,
                     type: { value: Integer, message: 'public.top_markets.non_integer_limit' },
                     values: { value: 1..1000, message: 'public.top_markets.invalid_limit' },
                     default: 1000,
                     desc: 'Limit the number of returned top performing prices. Default to 1000.'
          end
          get "/recommended" do
            # matchers for the purpose of substituting symbols in price_change_percent in order to sort as decimals
            matchers = {
              "-" => "",
              "+" => "",
              "%" => "",
              "." => "."
            }

            # Filter markets to only idr markets for SPEZA Indonesia only
            ::Market.enabled.where(bid_unit: 'idr').ordered.inject({}) do |h, m|
              h[m.id] = format_ticker Global[m.id].ticker
              # Return top performing pair sorted by volume
              @markets = h.sort_by { |k,v| -v[:ticker][:price_change_percent].dup.gsub!(/\W/, matchers).to_d }[0..(params[:limit]-1)].to_h
            end

            @markets.each do |k, v|
              currency = ::Market.enabled.find(k).ask_unit
              temp_hash = Hash.new
              temp_hash["ask_unit"] = currency
              temp_hash["bid_unit"] = ::Market.enabled.find(k).bid_unit
              temp_hash["icon_url"] = ::Currency.enabled.find(currency).icon_url
              @markets[k][:ticker] = v[:ticker].merge(temp_hash)
            end
          end

          desc 'Get top digital asset markets.',
            is_array: true,
            success: API::V2::Entities::Market
          params do
            optional :limit,
                     type: { value: Integer, message: 'public.top_markets.non_integer_limit' },
                     values: { value: 1..1000, message: 'public.top_markets.invalid_limit' },
                     default: 1000,
                     desc: 'Limit the number of returned top performing prices. Default to 1000.'
          end
          get "/top" do
            # Top 4 Digital Assets
            btc = format_ticker Global['btcusdt'].ticker
            eth = format_ticker Global['ethusdt'].ticker
            xrp = format_ticker Global['xrpusdt'].ticker
            ltc = format_ticker Global['ltcusdt'].ticker
            link = format_ticker Global['linkusdt'].ticker
            zrx = format_ticker Global['zrxusdt'].ticker

            @markets = {"btc": btc}.merge({"eth": eth}).merge({"xrp": xrp}).merge({"ltc": ltc}).merge({"link": link}).merge({"zrx": zrx})

            @markets.each do |k, v|
              temp_hash = Hash.new
              temp_hash["icon_url"] = ::Currency.enabled.find(k).icon_url
              @markets[k][:ticker] = v[:ticker].merge(temp_hash)
            end

            # all_markets = ::Market.enabled.ordered.inject({}) do |h, m|
            #   h[m.id] = format_ticker Global[m.id].ticker
            #   # Return top performing pair sorted by volume
            #   h.sort_by { |k,v| -v[:ticker][:volume] }.to_h
            # end
          end

          desc 'Get the order book of specified market.',
            is_array: true,
            success: API::V2::Entities::OrderBook
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.enabled.ids }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:id] }
            optional :asks_limit,
                     type: { value: Integer, message: 'public.order_book.non_integer_ask_limit' },
                     values: { value: 1..200, message: 'public.order_book.invalid_ask_limit' },
                     default: 20,
                     desc: 'Limit the number of returned sell orders. Default to 20.'
            optional :bids_limit,
                     type: { value: Integer, message: 'public.order_book.non_integer_bid_limit' },
                     values: { value: 1..200, message: 'public.order_book.invalid_bid_limit' },
                     default: 20,
                     desc: 'Limit the number of returned buy orders. Default to 20.'
          end
          get ":market/order-book" do
            asks = OrderAsk.active.with_market(params[:market]).matching_rule.limit(params[:asks_limit])
            bids = OrderBid.active.with_market(params[:market]).matching_rule.limit(params[:bids_limit])
            book = OrderBook.new asks, bids
            present book, with: API::V2::Entities::OrderBook
          end

          desc 'Get recent trades on market, each trade is included only once. Trades are sorted in reverse creation order.',
            is_array: true,
            success: API::V2::Entities::Trade
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.enabled.ids }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:id] }
            optional :limit,
                     type: { value: Integer, message: 'public.trade.non_integer_limit' },
                     values: { value: 1..1000, message: 'public.trade.invalid_limit' },
                     default: 100,
                     desc: 'Limit the number of returned trades. Default to 100.'
            optional :page,
                     type: { value: Integer, message: 'public.trade.non_integer_page' },
                     values: { value: -> (p){ p.try(:positive?) }, message: 'public.trade.non_positive_page'},
                     default: 1,
                     desc: 'Specify the page of paginated results.'
            optional :timestamp,
                     type: { value: Integer, message: 'public.trade.non_integer_timestamp' },
                     desc: "An integer represents the seconds elapsed since Unix epoch."\
                       "If set, only trades executed before the time will be returned."
            optional :order_by,
                     type: String,
                     values: { value: %w(asc desc), message: 'public.trade.invalid_order_by' },
                     default: 'desc',
                     desc: "If set, returned trades will be sorted in specific order, default to 'desc'."
          end
          get ":market/trades" do
            Trade.order(order_param)
                 .tap { |q| q.where!(market: params[:market]) if params[:market] }
                 .tap { |q| present paginate(q), with: API::V2::Entities::Trade }
          end

          desc 'Get depth or specified market. Both asks and bids are sorted from highest price to lowest.'
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.enabled.ids }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:id] }
            optional :limit,
                     type: { value: Integer, message: 'public.market_depth.non_integer_limit' },
                     values: { value: 1..1000, message: 'public.market_depth.invalid_limit' },
                     default: 300,
                     desc: 'Limit the number of returned price levels. Default to 300.'
          end
          get ":market/depth" do
            global = Global[params[:market]]
            asks = global.asks[0,params[:limit]].reverse
            bids = global.bids[0,params[:limit]]
            { timestamp: Time.now.to_i, asks: asks, bids: bids }
          end

          desc 'Get OHLC(k line) of specific market.'
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.enabled.ids }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:id] }
            optional :period,
                     type: { value: Integer, message: 'public.k_line.non_integer_period' },
                     values: { value: KLineService::AVAILABLE_POINT_PERIODS, message: 'public.k_line.invalid_period' },
                     default: 1,
                     desc: "Time period of K line, default to 1. You can choose between #{KLineService::AVAILABLE_POINT_PERIODS.join(', ')}"
            optional :time_from,
                     type: { value: Integer, message: 'public.k_line.non_integer_time_from' },
                     allow_blank: { value: false, message: 'public.k_line.empty_time_from' },
                     desc: "An integer represents the seconds elapsed since Unix epoch. If set, only k-line data after that time will be returned."
            optional :time_to,
                     type: { value: Integer, message: 'public.k_line.non_integer_time_to' },
                     allow_blank: { value: false, message: 'public.k_line.empty_time_to' },
                     desc: "An integer represents the seconds elapsed since Unix epoch. If set, only k-line data till that time will be returned."
            optional :limit,
                     type: { value: Integer, message: 'public.k_line.non_integer_limit' },
                     values: { value: KLineService::AVAILABLE_POINT_LIMITS, message: 'public.k_line.invalid_limit' },
                     default: 30,
                     desc: "Limit the number of returned data points default to 30. Ignored if time_from and time_to are given."
          end
          get ":market/k-line" do
            KLineService
              .new(params[:market], params[:period])
              .get_ohlc(params.slice(:limit, :time_from, :time_to))
          end

          desc 'Get OHLC(k line) of all markets.'
          params do
            optional :period,
                     type: { value: Integer, message: 'public.k_line.non_integer_period' },
                     values: { value: KLineService::AVAILABLE_POINT_PERIODS, message: 'public.k_line.invalid_period' },
                     default: 1,
                     desc: "Time period of K line, default to 1. You can choose between #{KLineService::AVAILABLE_POINT_PERIODS.join(', ')}"
            optional :time_from,
                     type: { value: Integer, message: 'public.k_line.non_integer_time_from' },
                     allow_blank: { value: false, message: 'public.k_line.empty_time_from' },
                     desc: "An integer represents the seconds elapsed since Unix epoch. If set, only k-line data after that time will be returned."
            optional :time_to,
                     type: { value: Integer, message: 'public.k_line.non_integer_time_to' },
                     allow_blank: { value: false, message: 'public.k_line.empty_time_to' },
                     desc: "An integer represents the seconds elapsed since Unix epoch. If set, only k-line data till that time will be returned."
            optional :limit,
                     type: { value: Integer, message: 'public.k_line.non_integer_limit' },
                     values: { value: KLineService::AVAILABLE_POINT_LIMITS, message: 'public.k_line.invalid_limit' },
                     default: 30,
                     desc: "Limit the number of returned data points default to 30. Ignored if time_from and time_to are given."
          end
          get "/k-line" do
            kline = {}
            ::Market.all.enabled.ids.each do |market|
              kline[market] = KLineService
                              .new(market, params[:period])
                              .get_ohlc(params.slice(:limit, :time_from, :time_to))
            end

            kline
          end

          desc 'Get ticker of all markets.'
          get "/tickers" do
            ::Market.enabled.ordered.inject({}) do |h, m|
              h[m.id] = format_ticker Global[m.id].ticker
              h
            end
          end

          desc 'Get ticker of specific market.'
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.enabled.ids }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:id] }
          end
          get "/:market/tickers/" do
            format_ticker Global[params[:market]].ticker
          end

          desc 'Get details for OTC'
          params do
            requires :currency_get # frontend get the currency list using https://uat2.speza.io/api/v2/peatio/public/currencies
            requires :currency_pay
            optional :order_by,
                     type: String,
                     values: { value: %w(asc desc), message: 'public.trade.invalid_order_by' },
                     default: 'desc',
                     desc: "If set, returned trades will be sorted in specific order, default to 'desc'."
          end
          get "/otc_details" do
            currency_get = Currency.enabled.find_by(id: params[:currency_get])
            currency_pay = Currency.enabled.find_by(id: params[:currency_pay])

            if currency_get && currency_pay
              # get the average of 10 latest_price for trades with given market
              trades = Trade.where("market_id = ? OR market_id = ?", "#{params[:currency_get]}#{params[:currency_pay]}", "#{params[:currency_pay]}#{params[:currency_get]}").order(order_param).first(10)

              sum = 0

              trades.each do |trade|
                sum = sum + trade.price
              end

              average_price = sum / trades.size

              # this is the exchange_fee of the currency the user want to buy (set by our own in that currency)
              exchange_fee = currency_get.otc_rate.to_d

              # Network fees only consist of eth-based now
              # TODO: Network fee for non-Eth
              if gas_price = currency_get.options["gas_price"].present?
                network_fee = gas_price.to_d/currency_get.base_factor.to_d
              else
                network_fee = 0.to_d
              end

              if ::Market.enabled.find_by(id: "#{params[:currency_get]}#{params[:currency_pay]}")
                expected_exchange_rate = average_price.to_d
              elsif ::Market.enabled.find_by(id: "#{params[:currency_pay]}#{params[:currency_get]}")
                # 1 divided by average_price for the reverse trade
                expected_exchange_rate = (1/average_price).to_d
              end

              if expected_exchange_rate
                # this api will return these 3 info like 'changelly', then frontend will use these info to do the calculation
                # instead of doing calculation at backend, lets do at frontend
                # will only call this api when currency change and recalculate and return back the following info
                # if just changing the volume at frontend(which is either currency_pay or currency_get), it won't call this api
                # these 3 info are based on 1 unit, frontend will times these info with the volume(which is amount_pay in our case) if needed
                {
                  expected_exchange_rate: expected_exchange_rate, # price meant for user
                  exchange_fee: exchange_fee,
                  network_fee: network_fee # no need times the volume or amount_pay
                }
                ######## CALCULATION ########
                ### now this calculation is including network_fee(if there is) regardless off-chain or on-chain
                ### CAUTION FOR ACCOUNTING ###
                ### means profit for off-chain = exchange_fee*volume + network_fee; on-chain = exchange*volume

                ### explanation from user side
                # amount_user_pay_with_currency_pay = buy_volume_in_currency_pay
                # amount_user_get_in_currency_get = (price - exchange_fee)*buy_volume_in_currency_pay - network_fee

                ###### frontend can use below formulae to calculate another amount if user insert value into either amount_pay(amount pay with currency_pay) or amount_get(amount get with currency_get)
                ### variable: expected_exchange_rate, exchange_fee, network_fee
                # amount_get = (expected_exchange_rate - exchange_fee)*amount_pay - network_fee
                # amount_pay = (amount_get + network_fee)/(expected_exchange_rate - exchange_fee)
              else
                body errors: 'Market not available'
                status 422
              end
            else
              body errors: 'Currency not available'
              status 422
            end

          end


        end

      end
    end
  end
end
