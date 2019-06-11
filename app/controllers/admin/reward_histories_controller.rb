module Admin
  class RewardHistoriesController < BaseController
    include Admin::CampaignHelper

    def index
      uri = URI("http://campaign:8002/api/v1/campaign_logs")
      params = { member_id: current_user.id }
      uri.query = URI.encode_www_form(params)

      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        campaign_logs = JSON.parse(res.body)
      else
        campaign_logs = []
      end

      @campaigns = Kaminari.paginate_array(campaign_logs).page(params[:page]).per(20)
    end

  end
end
