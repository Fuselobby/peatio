# encoding: UTF-8
# frozen_string_literal: true

module Admin
  class AnalystsController < BaseController

    before_action :init_date_range, only: [:index, :top_spender, :top_trader, :hot_trade]


    def index
      created_at_from = Date.parse(@date_range.split('-')[0].strip).beginning_of_day
      created_at_to = Date.parse(@date_range.split('-')[1].strip).end_of_day 
      db_trade = Trade.select('ask_member_id As ask_member_id', 'market_id As market_id')
      db_trade = db_trade.where('created_at > ?', created_at_from) if created_at_from.present?
      db_trade = db_trade.where('created_at < ?', created_at_to) if created_at_to.present?
      db_trade = db_trade.order('sum_funds desc') 
      db_trade = db_trade.group(:ask_member_id, :market_id).limit(10) 
      @trades = db_trade.sum(:funds) 
    end



    def top_spender
      created_at_from = Date.parse(@date_range.split('-')[0].strip).beginning_of_day
      created_at_to = Date.parse(@date_range.split('-')[1].strip).end_of_day 
      db_trade = Trade.select('ask_member_id As ask_member_id', 'market_id As market_id')
      db_trade = db_trade.where('created_at > ?', created_at_from) if created_at_from.present?
      db_trade = db_trade.where('created_at < ?', created_at_to) if created_at_to.present?
      db_trade = db_trade.order('sum_funds desc') 
      db_trade = db_trade.group(:ask_member_id, :market_id).limit(10) 
      @trades = db_trade.sum(:funds) 
    end



    def top_trader
      created_at_from = Date.parse(@date_range.split('-')[0].strip).beginning_of_day
      created_at_to = Date.parse(@date_range.split('-')[1].strip).end_of_day 
      db_trade = Trade.select('ask_member_id As ask_member_id', 'market_id As market_id')
      db_trade = db_trade.where('created_at > ?', created_at_from) if created_at_from.present?
      db_trade = db_trade.where('created_at < ?', created_at_to) if created_at_to.present?
      db_trade = db_trade.order('count_funds desc') 
      db_trade = db_trade.group(:ask_member_id, :market_id).limit(10) 
      @trades = db_trade.count(:funds) 
    end


    def hot_trade
      created_at_from = Date.parse(@date_range.split('-')[0].strip).beginning_of_day
      created_at_to = Date.parse(@date_range.split('-')[1].strip).end_of_day 
      db_trade = Trade.select('market_id As market_id')
      db_trade = db_trade.where('created_at > ?', created_at_from) if created_at_from.present?
      db_trade = db_trade.where('created_at < ?', created_at_to) if created_at_to.present?
      db_trade = db_trade.order('sum_funds desc') 
      db_trade = db_trade.group(:market_id).limit(10) 
      @trades = db_trade.sum(:funds) 
    end

 

  private
 


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
