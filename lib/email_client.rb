module EmailClient
  	# Email functions 
  	class Sendgrid
	  def email_notify(recipient, from, subject, content_type, content_body)
	    begin
	      url = "https://api.sendgrid.com/v3/mail/send"
	      uri = URI.parse(url)

	      http = Net::HTTP.new(uri.host, uri.port)
	      http.use_ssl = true
	      request = Net::HTTP::Post.new(uri.path)

	      request.add_field("Authorization", "Bearer #{ENV.fetch('SENDGRID_API_KEY')}")
	      request.add_field("Content-Type", "application/json")

	      body = {personalizations: [{to: [{email: recipient}], subject: subject}], from: {email: from},content: [{type: content_type, value: content_body}]}

	      request.body = body.to_json

	      http.request(request)
	    rescue Exception => ex
	      Rails.logger.error "[Email Notify Error] #{ex.message}"
	      Rails.logger.error ex.backtrace.join("\n")
	    end
	  end
	end
end