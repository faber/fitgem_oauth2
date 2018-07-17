module FitgemOauth2
  class InvalidDateArgument < ArgumentError
  end

  class InvalidTimeArgument < ArgumentError

  end

  class InvalidArgumentError < ArgumentError
  end

  # HTTP errors
  class ApiResponseError < StandardError
    attr_reader :status, :response_body

    def initialize(status, response_body={})
      @status = status
      @response_body = response_body || {}
      super(
        format(
          '%d: %s',
          status,
          response_body.inspect
        )
      )
    end

    def error_types
      @error_types ||= response_body['errors'].kind_of?(Array) ?
                         response_body['errors'].map { |e| e['errorType'] } :
                         []
    end

    [ :expired_token,
      :insufficient_scope,
      :invalid_grant,
      :invalid_token
    ].each do |error_type|
      define_method("#{error_type}?") do
        error_types.include?(error_type.to_s)
      end
    end
  end

  # class BadRequestError < StandardError
  # end

  # class UnauthorizedError < StandardError
  # end

  # class ForbiddenError < StandardError
  # end

  # class NotFoundError < StandardError
  # end

  # class ServerError < StandardError
  # end
end
