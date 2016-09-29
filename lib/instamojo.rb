class Instamojo
  # Status values that we are concerned with:
  PAYMENT_REQUEST_STATUS_PENDING = -'Pending'
  PAYMENT_REQUEST_STATUS_SENT = -'Sent'
  PAYMENT_STATUS_CREDITED = -'Credit'
  PAYMENT_STATUS_FAILED = -'Failed'

  # Raised when Instamojo API fails to create a payment request. This is handled in
  # BatchApplicationController#stage_1_submit.
  class PaymentRequestCreationFailed < StandardError; end

  def create_payment_request(amount:, buyer_name:, email:)
    payment_request = raw_create_payment_request(amount, buyer_name, email)[:payment_request]

    {
      id: payment_request[:id],
      status: payment_request[:status],
      short_url: payment_request[:shorturl],
      long_url: payment_request[:longurl]
    }
  end

  def payment_details(payment_request_id:, payment_id:)
    payment_request = raw_payment_details(payment_request_id, payment_id)[:payment_request]
    payment = payment_request[:payment]

    {
      payment_request_status: payment_request[:status],
      payment_status: payment[:status],
      fees: payment[:fees]
    }
  end

  def payment_request_details(payment_request_id:)
    payment_request = raw_payment_request_details(payment_request_id)[:payment_request]

    {
      payment_request_status: payment_request[:status],
      short_url: payment_request[:shorturl],
      redirect_url: payment_request[:redirect_url],
      webhook_url: payment_request[:webhook]
    }
  end

  def raw_create_payment_request(amount, buyer_name, email)
    uri = URI(payment_request_endpoint)
    request = Net::HTTP::Post.new(uri)

    request.set_form_data payment_request_params(amount, buyer_name, email)
    request['X-Api-Key'] = api_key
    request['X-Auth-Token'] = auth_token

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true

    raw_response = http.request(request)

    # Parse the response
    begin
      response = JSON.parse(raw_response.body).with_indifferent_access
    rescue JSON::ParserError
      raise PaymentRequestCreationFailed, "Failed to parse the response from Instamojo API as JSON: #{raw_response.body}"
    end

    unless response.key?(:success)
      raise PaymentRequestCreationFailed, "Response from Instamojo API was valid JSON, but did not contain the success key: #{raw_response.body}"
    end

    response
  end

  def raw_payment_details(payment_request_id, payment_id)
    uri = URI(payment_details_endpoint(payment_request_id, payment_id))
    request = Net::HTTP::Get.new(uri)

    request['X-Api-Key'] = api_key
    request['X-Auth-Token'] = auth_token

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true

    raw_response = http.request(request)

    # Parse the response
    response = JSON.parse(raw_response.body).with_indifferent_access

    raise "Failed to fetch payment details. Please check: #{raw_response.body}" unless response[:success]

    response
  end

  def raw_payment_request_details(payment_request_id)
    uri = URI(payment_request_details_endpoint(payment_request_id))
    request = Net::HTTP::Get.new(uri)

    request['X-Api-Key'] = api_key
    request['X-Auth-Token'] = auth_token

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true

    raw_response = http.request(request)

    # Parse the response
    response = JSON.parse(raw_response.body).with_indifferent_access

    raise "Failed to fetch payment request details. Please check: #{raw_response.body}" unless response[:success]

    response
  end

  private

  def payment_request_params(amount, buyer_name, email)
    params = {
      purpose: 'Application to SV.CO',
      amount: amount.to_s,
      buyer_name: buyer_name,
      email: email,
      redirect_url: redirect_url,
      send_email: Rails.env.production?,
      send_sms: false,
      allow_repeated_payments: false
    }

    params[:webhook] = webhook_url if Rails.env.production?
    params
  end

  def redirect_url
    Rails.application.routes.url_helpers.instamojo_redirect_url
  end

  def webhook_url
    Rails.application.routes.url_helpers.instamojo_webhook_url
  end

  def base_url
    Rails.application.secrets.instamojo_url
  end

  def payment_request_endpoint
    [base_url, 'payment-requests'].join('/') + '/'
  end

  def payment_request_details_endpoint(payment_request_id)
    [base_url, 'payment-requests', payment_request_id].join('/') + '/'
  end

  def payment_details_endpoint(payment_request_id, payment_id)
    [base_url, 'payment-requests', payment_request_id, payment_id].join('/') + '/'
  end

  def api_key
    Rails.application.secrets.instamojo_api_key
  end

  def auth_token
    Rails.application.secrets.instamojo_auth_token
  end
end
