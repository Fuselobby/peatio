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
      end
    end
  end
end
