module Admin
  class CampaignPostsController < BaseController
    include Admin::CampaignHelper

    def index
      uri = URI("http://campaign:8002/api/v1/campaign_posts")
      data = {
        sort_col: params[:sort_col] || 'created_at',
        sort_dir: params[:sort_dir] || 'desc'
      }
      uri.query = URI.encode_www_form(data)
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        campaign_posts = JSON.parse(res.body)
      else
        campaign_posts = []
      end

      @count = campaign_posts.count
      @campaign_posts = Kaminari.paginate_array(campaign_posts).page(params[:page]).per(10)
    end

    def show
      uri = URI("http://campaign:8002/api/v1/campaign_posts/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_post = JSON.parse(res.body)
        @image_url = "http://campaign:8002" + @campaign_post["image_url"] if @campaign_post["image_url"].present?
      else
      end
    end

    def edit
      uri = URI("http://campaign:8002/api/v1/campaign_posts/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_post = JSON.parse(res.body)
        @image_url = "http://campaign:8002" + @campaign_post["image_url"] if @campaign_post["image_url"].present?
      end
    end

    def update
      if params[:upload].present?
        image = File.open(params[:upload].path) {|img| img.read}
        encoded_image = Base64.encode64(image)
      end

      uri = URI("http://campaign:8002/api/v1/campaign_posts/#{params[:id]}")
      req = Net::HTTP::Put.new(uri)
      campaign_post_data = {
        subject: params[:subject],
        body: params[:body],
        status: params[:status],
        upload: encoded_image
      }
      req.set_form_data(campaign_post_data)

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @campaign_post = JSON.parse(res.body)
        redirect_to admin_campaign_post_path(@campaign_post["id"])
      else
        redirect_to edit_admin_campaign_post_path(params["id"])
      end
    end

  end
end
