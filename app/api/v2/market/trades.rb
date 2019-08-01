# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Market
      class Trades < Grape::API
        helpers API::V2::Market::NamedParams

        desc 'Get your executed trades. Trades are sorted in reverse creation order.',
          is_array: true,
          success: API::V2::Entities::Trade
        params do
          optional :market,
                   type: String,
                   values: { value: -> { ::Market.enabled.ids }, message: 'market.market.doesnt_exist' },
                   desc: -> { V2::Entities::Market.documentation[:id] }
          use :trade_filters
        end
        get '/trades' do
          current_user
            .trades
            .order(order_param)
            .tap { |q| q.where!(market: params[:market]) if params[:market] }
            .tap { |q| q.where!('created_at >= ?', Time.at(params[:time_from])) if params[:time_from] }
            .tap { |q| q.where!('created_at < ?', Time.at(params[:time_to])) if params[:time_to] }
            .tap { |q| present paginate(q), with: API::V2::Entities::Trade, current_user: current_user }
        end

        desc 'Get trades'
        get '/campaign_trades' do
          Trade.all
            .tap { |q| q.where!(market_id: params[:market_id]) if params[:market_id].present? }
            .tap { |q| q.where!("created_at >= ?", params[:from]) if params[:from].present? }
            .tap { |q| q.where!("created_at < ?", params[:to]) if params[:to].present? }
            .order('created_at asc')
        end

        desc 'Execute OTC'
        # frontend will do all the calculation and pass the params to here
        # this api just do the sub_fund, plus_fund, withdrawal, and then create otc_transaction
        params do
          requires :currency_get # currency the user want to buy/get
          requires :currency_pay # currency the user want to sell/pay
          requires :uid # uid of user making otc transaction
          requires :amount_pay # exact amount user pay in currency_pay
          requires :amount_get # exact amount user will get in currency_get (frontend pass the value after all the calculation)
          requires :address # outside wallet address OR inside address (frontend get using https://uat2.speza.io/api/v2/peatio/account/deposit_address/{eth})
          #######################
          # below is for otc_transaction record and accounting purpose
          # frontend get below params using https://uat2.speza.io/api/v2/peatio/public/markets/otc_details
          requires :volume
          requires :expected_exchange_rate # expected_exchange_rate get from api above
          requires :exchange_fee # exchange_fee get from api above
          requires :network_fee # network_fee frontend get from api above
        end
        post '/execute_otc' do
          member = Member.find_by!(uid: params[:uid])
          account_pay = member.get_account(params[:currency_pay])

          account_pay.with_lock do
            # make sure withdrawal account balance is sufficient for the transaction else won't proceed
            if account_pay.balance >= params[:amount_pay].to_d
              # check off-chain or on-chain
              if payment_address = PaymentAddress.find_by(currency_id: params[:currency_get], address: params[:address])
                # off-chain
                type = 'off-chain'
                account_get = payment_address.account
                ActiveRecord::Base.transaction do
                  account_pay.sub_funds(params[:amount_pay].to_d) # subtract amount_pay from account_pay
                  account_get.plus_funds(params[:amount_get].to_d) # plus amount_get to account_get
                  create_otc_transaction(member, type, params) # create otc_transaction for record purpose, then after_create otc_transaction will trigger accounting record(pending)
                end

              else
                # on-chain
                # TODO: make on-chain withdrawal may be a service
                type = 'on-chain'
                currency_get = Currency.enabled.find_by(id: params[:currency_get])
                if wallet = Wallet.active.find_by(kind: :hot, currency: currency_get)

                  DEFAULT_ETH_FEE = { gas_limit: 21_000, gas_price: 1_000_000_000 }.freeze
                  DEFAULT_ERC20_FEE = { gas_limit: 90_000, gas_price: 1_000_000_000 }.freeze

                  options = {}
                  currency_options = currency_get.options.symbolize_keys

                  ActiveRecord::Base.transaction do
                    # check whether currency_get is erc20
                    if currency_get.options["erc20_contract_address"].present?
                      # erc20
                      options = DEFAULT_ERC20_FEE
                                  .merge(currency_options.slice(:gas_limit, :gas_price))
                                  .merge(options)

                      WalletClient[wallet].create_erc20_withdrawal!(
                        { address: wallet.address, secret: wallet.secret },
                        { address: params[:address] },
                        amount_to_base_unit!(params[:amount_get], currency_get),
                        options.merge(contract_address: currency_get.erc20_contract_address)
                      )
                    else
                      # non-erc20
                      case params[:currency_get]
                      when "eth"
                        options = DEFAULT_ETH_FEE
                                    .merge(currency_options.slice(:gas_limit, :gas_price))
                                    .merge(options)

                        WalletClient[wallet].create_eth_withdrawal!(
                          { address: wallet.address, secret: wallet.secret },
                          { address: params[:address] },
                          amount_to_base_unit!(params[:amount_get], currency_get),
                          options
                        )
                      when "xrp"
                        WalletClient[wallet].create_withdrawal!(
                          { address: wallet.address, secret: wallet.secret },
                          { address: params[:address] },
                          params[:amount_get].to_d,
                          options
                        )
                      else
                        WalletClient[wallet].create_withdrawal!(
                          { address: wallet.address },
                          { address: params[:address] },
                          params[:amount_get].to_d,
                          options
                        )
                      end
                    end

                    account_pay.sub_funds(params[:amount_pay].to_d) # subtract amount_pay from account_pay
                    create_otc_transaction(member, type, params) # create otc_transaction for record purpose, then after_create otc_transaction will trigger accounting record(pending)
                  end

                end

              end
            else
              body errors: 'Account balance is insufficient'
              status 422
            end
          end

        end
      end
    end
  end
end
