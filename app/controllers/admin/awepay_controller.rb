module Admin
  class AwepayController < BaseController
    def index
      puts "Currency: #{params[:currency]}"
      puts "ID: #{params[:id]}"
      puts "RID: #{params[:rid]}"

      puts "Path: #{request.protocol}#{request.host_with_port}/admin/withdraws/#{params[:currency]}/#{params[:id]}"

      url = withdraw_form_url
      puts "url: #{url}"
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.path)

      body = {
        amount: params[:amount],
        currency: params[:currency],
        successurl: admin_withdraw_url(params[:currency], params[:id]),
        failureurl: admin_withdraw_url(params[:currency], params[:id]),
        rid: params[:rid]
      }

      request.body = body.to_json

      res = http.request(request)

      # Call awepay api withdraw_form and render it
      # Pass currency, success/failure url, amount, RID
      # template = "<form action=https://secure.awepay.com/txHandler.php method=post>\n\tsid: <input type=\"text\" name=\"sid\" value=2582><BR>\n\tpostback url: <input type=\"text\" name=\"postback_url\" value=https://uat2.speza.io/api/v1/applogic/callback/awepay_withdraw><BR>\n    card type: <input type=\"text\" name=\"card_type\" value=p2p><BR>\n    tx_action: <input type=\"text\" name=\"tx_action\" value=PAYOUT><BR>\n    amount: <input type=\"text\" name=\"amount\" value=50><BR>\n    currency: <input type=\"text\" name=\"currency\" value=myr><BR>\n    card_name: <input type=\"text\" name=\"account_name\" value=chris><BR>\n    card_number: <input type=\"text\" name=\"account_number\" value=123><BR>\n    bank_code: <input type=\"text\" name=\"bank_code\" value=MBB><BR>\n    \n\tsuccessurl: <input type=\"text\" name=\"successurl\" value=localhost:3000/admin/withdraws/usd/1><BR>\n\tfailureurl: <input type=\"text\" name=\"failureurl\" value=localhost:3000/admin/withdraws/usd/1><BR>\n\t<input type=\"submit\">\n</form>\n"
      render :html => res.html_safe
    end

    private
    def withdraw_form_url
      protocol = request.protocol
      hostname = request.host_with_port
      "#{protocol}#{hostname}/api/v1/applogic/awepay/withdraw"
    end

    def admin_withdraw_url(currency, id)
      "#{request.protocol}#{request.host_with_port}/admin/withdraws/#{currency}/#{id}"
    end
  end
end
