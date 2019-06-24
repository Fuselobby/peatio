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
            .tap { |q| present paginate(q), with: API::V2::Entities::Trade, current_user: current_user }
        end

        desc 'Get trades'
        get '/campaign_trades' do
          Trade.all
            .tap { |q| q.where!(market_id: params[:market_id]) if params[:market_id].present? }
            .tap { |q| q.where!("created_at >= ?", params[:from]) if params[:from].present? }
            .tap { |q| q.where!("created_at <= ?", params[:to]) if params[:to].present? }
            .order('created_at asc')
        end
      end
    end
  end
end
