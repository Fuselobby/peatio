module Admin
  class CampaignsController < BaseController
    def index
      uri = URI("http://campaign:8002/api/v1/campaigns")
      data = {
        sort_col: params[:sort_col] || 'created_at',
        sort_dir: params[:sort_dir] || 'desc'
      }
      uri.query = URI.encode_www_form(data)
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        campaigns = JSON.parse(res.body)
      else
        campaigns = []
      end

      @campaigns = Kaminari.paginate_array(campaigns).page(params[:page]).per(10)
    end

    def new
      uri = URI("http://campaign:8002/api/v1/campaign_options")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        campaign_options = JSON.parse(res.body)
      else
        campaign_options = []
      end

      active_campaign_options = campaign_options.select{ |c| ["ACTIVE"].include?(c["status"]) }

      @execution_types = active_campaign_options.select{ |a| ["Execution Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
      @campaign_types = active_campaign_options.select{ |a| ["Campaign Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
      @audience_types = active_campaign_options.select{ |a| ["Audience Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
      @reward_types = active_campaign_options.select{ |a| ["Reward Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
      @calculation_types = active_campaign_options.select{ |a| ["Calculation Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
      @reward_currencies = Currency.where(enabled: true).distinct.pluck(:id).sort
      @frequency_units = ['seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']
    end

    def show
      uri = URI("http://campaign:8002/api/v1/campaigns/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign = JSON.parse(res.body)
      else
      end
    end

    def create
      if params[:execution_type] == 'Schedule'
        frequency = params[:frequency_interval] + " " + params[:frequency_unit] if params[:frequency_interval] && params[:frequency_unit]
      end
      uri = URI("http://campaign:8002/api/v1/campaigns")
      req = Net::HTTP::Post.new(uri)
      campaign_data = {
        from_date: params[:from_date],
        to_date: params[:to_date],
        campaign_name: params[:campaign_name],
        campaign_types: params[:campaign_types].to_json,
        audience_type: params[:audience_type],
        reward_type: params[:reward_type],
        reward_currency: params[:reward_currency],
        reward_amount: params[:reward_amount],
        calculation_type: params[:calculation_type],
        description: params[:description],
        status: params[:status],
        frequency: frequency,
        execution_type: params[:execution_type],
        occurence: params[:occurence]
      }
      req.set_form_data(campaign_data)

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign = JSON.parse(res.body)
        redirect_to admin_campaign_path(@campaign["id"])
      else
        redirect_to new_admin_campaign_path
      end
    end

    def edit
      uri = URI("http://campaign:8002/api/v1/campaigns/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign = JSON.parse(res.body)

        @uri = URI("http://campaign:8002/api/v1/campaign_options")
        @res = Net::HTTP.get_response(@uri)

        case @res
        when Net::HTTPSuccess, Net::HTTPRedirection
          campaign_options = JSON.parse(@res.body)
        else
          campaign_options = []
        end

        active_campaign_options = campaign_options.select{ |c| ["ACTIVE"].include?(c["status"]) }

        @execution_types = active_campaign_options.select{ |a| ["Execution Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
        @campaign_types = active_campaign_options.select{ |a| ["Campaign Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
        @audience_types = active_campaign_options.select{ |a| ["Audience Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
        @reward_types = active_campaign_options.select{ |a| ["Reward Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
        @calculation_types = active_campaign_options.select{ |a| ["Calculation Type"].include?(a["option_type"]) }.map{ |k| k["option_name"] }.uniq.sort
        @reward_currencies = Currency.where(enabled: true).distinct.pluck(:id).sort
        @frequency_units = ['seconds', 'minutes', 'hours', 'days', 'weeks', 'months', 'years']
      end
    end

    def update
      if params[:execution_type] == 'Schedule'
        frequency = params[:frequency_interval] + " " + params[:frequency_unit] if params[:frequency_interval] && params[:frequency_unit]
      end
      uri = URI("http://campaign:8002/api/v1/campaigns/#{params[:id]}")
      req = Net::HTTP::Put.new(uri)
      campaign_data = {
        from_date: params[:from_date],
        to_date: params[:to_date],
        campaign_name: params[:campaign_name],
        campaign_types: params[:campaign_types].to_json,
        audience_type: params[:audience_type],
        reward_type: params[:reward_type],
        reward_currency: params[:reward_currency],
        reward_amount: params[:reward_amount],
        calculation_type: params[:calculation_type],
        description: params[:description],
        status: params[:status],
        frequency: frequency,
        execution_type: params[:execution_type],
        occurence: params[:occurence]
      }
      req.set_form_data(campaign_data)

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign = JSON.parse(res.body)
        redirect_to admin_campaign_path(@campaign["id"])
      else
        redirect_to edit_admin_campaign_path(params["id"])
      end
    end

  end
end
