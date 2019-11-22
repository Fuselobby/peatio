# encoding: UTF-8
# frozen_string_literal: true

module Admin
  class NoticesController < BaseController
    def index
      @notices = Notice.all.page(params[:page]).per(100)
    end

    def show
      @notice = Notice.find(params[:id])
    end
    
    def new
      @notice = Notice.new
      render :show
    end

    def create

      @notice = Notice.new(notice_params)
      if @notice.save

        activity_record(user: current_user.id, action: 'create', result: 'succeed', topic: 'Notices')
        redirect_to admin_notices_path
      else
        activity_record(user: current_user.id, action: 'create', result: 'failed', topic: 'Notices')
        flash[:alert] = @notice.errors.full_messages.first
        render :show
      end
    end

    def update
      @notice = Notice.find(params[:id])
      if @notice.update(notice_params)
        activity_record(user: current_user.id, action: 'update', result: 'succeed', topic: 'Notices')
        redirect_to admin_notices_path
      else
        activity_record(user: current_user.id, action: 'update', result: 'failed', topic: 'Notices')
        flash[:alert] = @notice.errors.full_messages.first
        redirect_to :back
      end
    end

    private

    def notice_params
      
      params.require(:notice).permit(permitted_notice_attributes).tap do |param|
        boolean_notice_attributes.each do |param|
          next unless params.key?(param)
          params[param] = params[param].in?(['1', 'true', true])
        end
      end
 
    end

    def permitted_notice_attributes
      attributes = [
        :notice_title,
        :notice_url,
        :description,
        :notice_date,
        :from_date,
        :to_date,
        :enabled
      ]

      attributes
    end

    def boolean_notice_attributes
      %i[ enabled ]
    end
  end
end