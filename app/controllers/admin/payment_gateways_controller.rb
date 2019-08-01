module Admin
  class PaymentGatewaysController < BaseController
    include Admin::CampaignHelper

    def index
      uri = URI("http://applogic:8080/api/v1/payment_gateways")
      data = {
        sort_col: params[:sort_col] || 'created_at',
        sort_dir: params[:sort_dir] || 'desc'
      }
      uri.query = URI.encode_www_form(data)
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        payment_gateways = JSON.parse(res.body)
      else
        payment_gateways = []
      end

      @count = payment_gateways.count
      @payment_gateways = Kaminari.paginate_array(payment_gateways).page(params[:page]).per(10)
    end

    def show
      uri = URI("http://applogic:8080/api/v1/payment_gateways/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @payment_gateway = JSON.parse(res.body)
      else
      end
    end

    def new
    end

    def create
      uri = URI("http://applogic:8080/api/v1/payment_gateways")
      req = Net::HTTP::Post.new(uri)
      data = {
        provider: params[:provider],
        rate: params[:rate]
      }
      req.set_form_data(data)

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @payment_gateway = JSON.parse(res.body)
        redirect_to admin_payment_gateway_path(@payment_gateway["id"])
      else
        redirect_to new_admin_payment_gateway_path
      end
    end

    def edit
      uri = URI("http://applogic:8080/api/v1/payment_gateways/#{params[:id]}")
      res = Net::HTTP.get_response(uri)

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @payment_gateway = JSON.parse(res.body)
      else
      end
    end

    def update
      uri = URI("http://applogic:8080/api/v1/payment_gateways/#{params[:id]}")
      req = Net::HTTP::Put.new(uri)
      data = {
        provider: params[:provider],
        rate: params[:rate]
      }
      req.set_form_data(data)

      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
      when Net::HTTPSuccess, Net::HTTPRedirection
        @payment_gateway = JSON.parse(res.body)
        redirect_to admin_payment_gateway_path(@payment_gateway["id"])
      else
        redirect_to edit_admin_payment_gateway_path(params["id"])
      end
    end

  end
end
