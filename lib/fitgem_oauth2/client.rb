require 'fitgem_oauth2/activity.rb'
require 'fitgem_oauth2/body_measurements.rb'
require 'fitgem_oauth2/devices.rb'
require 'fitgem_oauth2/errors.rb'
require 'fitgem_oauth2/food.rb'
require 'fitgem_oauth2/friends.rb'
require 'fitgem_oauth2/heartrate.rb'
require 'fitgem_oauth2/sleep.rb'
require 'fitgem_oauth2/subscriptions.rb'
require 'fitgem_oauth2/users.rb'
require 'fitgem_oauth2/utils.rb'
require 'fitgem_oauth2/version.rb'

require 'base64'
require 'faraday'

module FitgemOauth2
  class Client

    DEFAULT_USER_ID = '-'
    DEFAULT_ACCEPT_LANGUAGE = 'en_US'
    API_VERSION = '1'

    attr_reader :client_id
    attr_reader :client_secret
    attr_reader :token
    attr_reader :user_id

    def initialize(
          client_id:,
          client_secret:,
          token: nil,
          user_id: nil,
          accept_language: nil,
          debug: false)
      @client_id = client_id
      @client_secret = client_secret
      @token = token
      @user_id = (user_id || DEFAULT_USER_ID)

      @accept_language = accept_language || DEFAULT_ACCEPT_LANGUAGE
      @connection = Faraday.new('https://api.fitbit.com') do |faraday|
        faraday.adapter Faraday.default_adapter
        if debug
          faraday.response :logger, ::Logger.new(STDOUT), bodies: true
        end
      end
    end

    def reconfigure(token)
      @token = token
    end

    def refresh_access_token(refresh_token)
      response = connection.post('/oauth2/token') do |request|
        encoded = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
        request.headers['Authorization'] = "Basic #{encoded}"
        request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        request.params['grant_type'] = 'refresh_token'
        request.params['refresh_token'] = refresh_token
      end
      JSON.parse(response.body)
    end

    def get_call(url)
      require_token!
      url = "#{API_VERSION}/#{url}"
      response = connection.get(url) { |request| set_headers(request) }
      parse_response(response)
    end

    def post_call(url, params = {})
      require_token!
      url = "#{API_VERSION}/#{url}"
      response = connection.post(url, params) { |request| set_headers(request) }
      parse_response(response)
    end

    def delete_call(url)
      require_token!
      url = "#{API_VERSION}/#{url}"
      response = connection.delete(url) { |request| set_headers(request) }
      parse_response(response)
    end

    private
    attr_reader :connection, :accept_language

    def require_token!
      unless token
        fail InvalidArgumentError, "must supply a token before making requests"
      end
    end

    def set_headers(request)
      request.headers['Authorization'] = "Bearer #{token}"
      request.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      request.headers['Accept-Language'] = accept_language
    end

    def parse_response(response)
      headers_to_keep = %w(fitbit-rate-limit-limit fitbit-rate-limit-remaining fitbit-rate-limit-reset)

      parsed_body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        {}
      end

      if response.status == 200
        body = parsed_body
        body = {body: body} if body.is_a?(Array)
        body.merge!(response.headers.slice(*headers_to_keep))
      else
        fail ApiResponseError.new(response.status, parsed_body)
      end
    end
  end
end
