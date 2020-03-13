require 'openssl'

module Binance
    class BinanceShareFunction
        @api_key = ENV["BINANCE_API_KEY"]
        @api_secret = ENV["BINANCE_API_SECRET"]

        class << self

            def get_apikey
                return @api_key
            end

            def get_apisecret
                return @api_secret
            end

            def build_error(response)
                JSON.parse(response.body)
            rescue StandardError => e
                "Code: #{response.env.status} Message: #{response.env.reason_phrase}"
            end

            def fatal(message)
                Logger.new($stderr).fatal message
            end

            def create_query(data)
                query = ""
                data.each { |key, value| query << "#{key}=#{value}&" }
                return query
            end
        
            def generate_body(data)
                query = create_query(data)
                sig = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @api_secret, query.chomp('&'))
                data.merge(signature: sig)
            end
        
            def get_api
                @connection = Faraday.new("https://www.binance.com") do |builder|
                    builder.adapter :em_synchrony
                end
            end

            def get_api_with_header
                @rest_api_connection = Faraday.new("https://api.binance.com") do |builder|
                    builder.adapter :em_synchrony
                    builder.headers['Content-Type'] = 'application/x-www-form-urlencoded'
                end
            end
        end
    end
end