# encoding: UTF-8
# frozen_string_literal: true

require_dependency 'admin/withdraws/base_controller'

module Admin
  module Withdraws
    class FiatsController < BaseController
      before_action :find_withdraw, only: [:show, :update, :destroy]

      def index
        @latest_withdraws  = ::Withdraws::Fiat.where(currency: currency)
                                              .where('created_at <= ?', 1.day.ago)
                                              .order(id: :desc)
                                              .includes(:member, :currency)
        @all_withdraws     = ::Withdraws::Fiat.where(currency: currency)
                                              .where('created_at > ?', 1.day.ago)
                                              .order(id: :desc)
                                              .includes(:member, :currency)
      end

      def show

      end

      def update
        @withdraw.transaction do
          @withdraw.accept!
          @withdraw.process!
          @withdraw.dispatch!
          @withdraw.success!

          recipient = "#{Member.find_by_id(@withdraw.member_id).email}"
          from = ENV.fetch('EMAIL_SENDER')
          memo = "#{@withdraw.amount} #{@withdraw.currency_id.upcase}"
     
          subject = "Withdrawal Approved"
          content_type = "text/plain"
          content = "The following withdrawal (Receipt ID: #{@withdraw.rid}) has been approved:\n#{memo}"

          EmailClient::Sendgrid.new.email_notify(recipient, from, subject, content_type, content)
        end
        redirect_to :back, notice: 'Withdraw successfully updated!'
      end

      def destroy
        @withdraw.reject!
        redirect_to :back, notice: 'Withdraw successfully destroyed!'
      end
    end
  end
end
