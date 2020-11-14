# frozen_string_literal: true

module HongikSso
  class CookieManager
    attr_accessor :cookies

    def initialize
      @cookies = []
    end

    def push_cookie(cookie_string)
      cookies << cookie_string
    end
  end
end
