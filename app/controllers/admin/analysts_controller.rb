# encoding: UTF-8
# frozen_string_literal: true

module Admin
  class AnalystsController < BaseController

    before_action :init_date_range, only: [:index]


    def index
      created_at_from = Date.parse(@date_range.split('-')[0].strip).beginning_of_day
      created_at_to = Date.parse(@date_range.split('-')[1].strip).end_of_day
      @currencies = Currency.ordered.page(params[:page]).per(100)
 

      db_trade = Trade.where('created_at > ?', created_at_from) if created_at_from.present?
      db_trade = db_trade.where('created_at < ?', created_at_to) if created_at_to.present?
      db_trade = db_trade.group(:ask_member_id, :market_id).sum(:funds)
 
      @trades = db_trade.page(params[:page]).per(100) 

 
    end


    def analysts_sheet
      created_at_from = Date.parse(@date_range.split('-')[0].strip).beginning_of_day
      created_at_to = Date.parse(@date_range.split('-')[1].strip).end_of_day
      @currencies = Currency.ordered.page(params[:page]).per(100)
    end


    def new
      @currency = Currency.new
      render :show
    end
 

    def show
      @currency = Currency.find(params[:id])
    end
 

  private

    def currency_params
      params.require(:currency).permit(permitted_currency_attributes).tap do |whitelist|
        boolean_currency_attributes.each do |param|
          next unless whitelist.key?(param)
          whitelist[param] = whitelist[param].in?(['1', 'true', true])
        end
        whitelist[:options] = params[:currency][:options].is_a?(String) ? \
                                  JSON.parse(params[:currency][:options]) : params[:currency][:options] \
                                  if params[:currency][:options]
      end
    end

    def permitted_currency_attributes
      attributes = %i[
        name
        symbol
        icon_url
        deposit_fee
        min_deposit_amount
        min_collection_amount
        withdraw_fee
        min_withdraw_amount
        withdraw_limit_24h
        withdraw_limit_72h
        enabled
        blockchain_key
        position
      ]

      if @currency.new_record?
        attributes += %i[
          code
          type
          base_factor
          precision ]
      end

      attributes
    end

    def boolean_currency_attributes
      %i[ enabled ]
    end


    def init_date_range
      if params[:date_range]
        @date_range = params[:date_range]
      else
        @date_range = Date.today.beginning_of_month.strftime("%Y/%m/%d") \
                      + "-" \
                      + Date.today.strftime("%Y/%m/%d")
      end
    end

  end
end
