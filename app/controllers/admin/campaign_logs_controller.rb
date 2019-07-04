module Admin
  class CampaignLogsController < BaseController
    include Admin::CampaignHelper

    def index
      uri = URI("http://campaign:8002/api/v1/campaign_logs")
      data = {
        sort_col: params[:sort_col] || 'request_date',
        sort_dir: params[:sort_dir] || 'desc'
      }
      uri.query = URI.encode_www_form(data)
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        campaign_logs = JSON.parse(res.body)
      else
        campaign_logs = []
      end

      @sums = campaign_logs.group_by { |h| h["receive_currency"] }.map do |k,v|
                {"currency" => k, "amount" => v.sum { |h1| h1["receive_amount"].to_d }}
              end
      @count = campaign_logs.count
      @campaign_logs = Kaminari.paginate_array(campaign_logs).page(params[:page]).per(10)
    end

    def show
      uri = URI("http://campaign:8002/api/v1/campaign_logs/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_log = JSON.parse(res.body)
      else
      end
    end
  end
end
