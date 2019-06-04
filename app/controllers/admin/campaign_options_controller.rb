module Admin
  class CampaignOptionsController < BaseController
    include Admin::CampaignHelper

    def index
      uri = URI("http://campaign:8002/api/v1/campaign_options")
      data = {
        sort_col: params[:sort_col] || 'created_at',
        sort_dir: params[:sort_dir] || 'desc'
      }
      uri.query = URI.encode_www_form(data)
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        campaign_options = JSON.parse(res.body)
      else
        campaign_options = []
      end

      @campaign_options = Kaminari.paginate_array(campaign_options).page(params[:page]).per(10)
    end

    def new
      @options_attributes = %i[table_name minimum].freeze
      options = {}
      @build_options_schema = (options.keys - @options_attributes.map(&:to_s)) \
                                  .map{|v| [v, { title: v.to_s.humanize, format: "table"}]}.to_h
      @set_options_values = options.keys.present?  ? \
                                options.keys.map{|v| [v, options[v]]}.to_h \
                                : @options_attributes.map(&:to_s).map{|v| [v, '']}.to_h
    end

    def show
      uri = URI("http://campaign:8002/api/v1/campaign_options/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_option = JSON.parse(res.body)
      else
      end
    end

    def create
      uri = URI("http://campaign:8002/api/v1/campaign_options")
      req = Net::HTTP::Post.new(uri)
      campaign_option_data = {
        option_name: params[:option_name],
        option_type: params[:option_type],
        status: params[:status],
        description: params[:description],
        json_data: params[:root].to_json
      }
      req.set_form_data(campaign_option_data)

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_option = JSON.parse(res.body)
        redirect_to admin_campaign_option_path(@campaign_option["id"])
      else
        redirect_to new_admin_campaign_option_path
      end
    end

    def edit
      uri = URI("http://campaign:8002/api/v1/campaign_options/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_option = JSON.parse(res.body)
        @options_attributes = %i[table_name minimum].freeze
        options = @campaign_option["json_data"] || {}
        @build_options_schema = (options.keys - @options_attributes.map(&:to_s)) \
                                    .map{|v| [v, { title: v.to_s.humanize, format: "table"}]}.to_h
        @set_options_values = options.keys.present?  ? \
                                  options.keys.map{|v| [v, options[v]]}.to_h \
                                  : @options_attributes.map(&:to_s).map{|v| [v, '']}.to_h
      else
      end
    end

    def update
      uri = URI("http://campaign:8002/api/v1/campaign_options/#{params[:id]}")
      req = Net::HTTP::Put.new(uri)
      campaign_option_data = {
        option_name: params[:option_name],
        option_type: params[:option_type],
        status: params[:status],
        description: params[:description],
        json_data: params[:root].to_json
      }
      req.set_form_data(campaign_option_data)

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_option = JSON.parse(res.body)
        redirect_to admin_campaign_option_path(@campaign_option["id"])
      else
        redirect_to edit_admin_campaign_option_path(params["id"])
      end
    end

  end
end
