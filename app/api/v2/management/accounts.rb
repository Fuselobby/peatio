# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Management
      class Accounts < Grape::API
        desc 'Queries the account balance for the given UID and currency.' do
          @settings[:scope] = :read_accounts
          success API::V2::Management::Entities::Balance
        end

        params do
          requires :uid, type: String, desc: 'The shared user ID.'
          requires :currency, type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
        end

        post '/accounts/balance' do
          member = Member.find_by!(uid: params[:uid])
          account = member.get_account(params[:currency])
          present account, with: API::V2::Management::Entities::Balance
          status 200
        end

        desc 'Adds fund to the given UID and currency.' do
          @settings[:scope] = :write_accounts
          success API::V2::Management::Entities::Balance
        end

        params do
          requires :uid, type: String, desc: 'The recipient user ID.'
          requires :currency, type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
          requires :amount, type: String, desc: 'Amount to add'
        end

        post '/accounts/add_rewards' do
          member = Member.find_by!(uid: params[:uid])
          account = member.get_account(params[:currency])
          amount = params[:amount].to_d
          currency = Currency.find_by_id(params[:currency])
          # Add funds to user wallet
          account.plus_funds(params[:amount].to_d) if account
          # Record as expense in accounting
          record_complete_operations(amount, currency, member)
          status 200
        end

        desc 'Deduct fund from the given UID and currency as payment.' do
          @settings[:scope] = :write_accounts
          success API::V2::Management::Entities::Balance
        end

        params do
          requires :uid, type: String, desc: 'The user ID.'
          requires :currency, type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
          requires :amount, type: String, desc: 'Amount to deduct'
        end

        post '/accounts/payment' do
          member = Member.find_by!(uid: params[:uid])
          account = member.get_account(params[:currency])
          amount = params[:amount].to_d
          currency = Currency.find_by_id(params[:currency])
          # Subtract funds from user wallet
          account.sub_funds(params[:amount].to_d) if account
          # Record as expense in accounting
          # record_complete_operations(amount, currency, member)
          status 200
        end

        desc 'Get member with given UID'
        params do
          requires :uid, type: String, desc: 'The member UID.'
        end
        get '/accounts/campaign_member' do
          Member.find_by(uid: params[:uid])
        end

        # desc 'Get the array of UID and balance of members having minimum balance in given currency account'
        # params do
        #   requires :currency_id, type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
        #   requires :minimum, type: String, desc: 'Minimum balance.'
        # end
        # get '/accounts/campaign_accounts' do
        #   ::Account.where(currency_id: params[:currency_id]).where("balance >= ?", params[:minimum]).joins(:member).pluck("members.uid", "accounts.balance", "accounts.id")
        # end

        desc 'Get the balance of given member in given currency account'
        params do
          requires :currency_id, type: String, values: -> { Currency.codes(bothcase: true) }, desc: 'The currency code.'
          requires :member_uid, type: String, desc: 'The member UID.'
        end
        get '/accounts/campaign_account_balance' do
          if member = Member.find_by!(uid: params[:member_uid])
            account = member.get_account(params[:currency_id])
            account.try(:balance)
          end
        end

      end
    end
  end
end
