# encoding: UTF-8
# frozen_string_literal: true

module API
  module V2
    module Market
      module Helpers

        # for eth based only
        def amount_to_base_unit!(amount, currency)
          x = amount.to_d * currency.base_factor
          unless (x % 1).zero?
            raise StandardError::Error, "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " +
                "#{amount.to_d} - #{x.to_d} must be equal to zero."
          end
          x.to_i
        end

        def create_otc_transaction(member, type, params)
          OtcTransaction.create!(
            member: member,
            currency_pay: params[:currency_pay],
            currency_get: params[:currency_get],
            destination_address: params[:address],
            price: params[:expected_exchange_rate],
            volume: params[:volume],
            exchange_fee: params[:exchange_fee],
            network_fee: params[:network_fee],
            amount_pay: params[:amount_pay],
            amount_get: params[:amount_get],
            otc_type: type
          )
        end

      end
    end
  end
end
