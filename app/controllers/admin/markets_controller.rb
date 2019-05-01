# encoding: UTF-8
# frozen_string_literal: true

module Admin
  class MarketsController < BaseController
    def index
      @markets = Market.ordered.page(params[:page]).per(100)
    end

    def new
      @market = Market.new
      render :show
    end

    def create
      @market = Market.new
      @market.assign_attributes(market_params)
      if @market.save
        activity_record(user: current_user.id, action: 'create', result: 'succeed', topic: 'markets')
        redirect_to admin_markets_path
      else
        activity_record(user: current_user.id, action: 'create', result: 'failed', topic: 'markets')
        flash[:alert] = @market.errors.full_messages.first
        render :show
      end
    end

    def show
      @market = Market.find(params[:id])
    end

    def update
      @market = Market.find(params[:id])
      if @market.update(market_params)
        activity_record(user: current_user.id, action: 'update', result: 'succeed', topic: 'markets')
        redirect_to admin_markets_path
      else
        activity_record(user: current_user.id, action: 'update', result: 'failed', topic: 'markets')
        flash[:alert] = @market.errors.full_messages.first
        redirect_to :back
      end
    end

  private

    def market_params
      params.require(:trading_pair).except(:id).permit(permitted_market_attributes).tap do |params|
        boolean_market_attributes.each do |param|
          next unless params.key?(param)
          params[param] = params[param].in?(['1', 'true', true])
        end
      end
    end

    def permitted_market_attributes
      attributes = [
        :bid_unit,
        :bid_fee,
        :ask_unit,
        :ask_fee,
        :enabled,
        :min_ask_price,
        :max_bid_price,
        :min_ask_amount,
        :min_bid_amount,
        :position
      ]

      if @market.new_record?
        attributes += [
          :ask_precision,
          :bid_precision
        ]
      end

      attributes
    end

    def boolean_market_attributes
      %i[enabled]
    end
  end
end
