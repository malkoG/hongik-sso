# typed: true
require "uri"
require "net/http"

require "hongik_sso/entrypoints"
require "hongik_sso/cookie_manager"
require "hongik_sso/request_manager"

module HongikSso
  class Client
    attr_reader :user_id, :password, :cookie_manager, :request_manager

    def initialize(user_id, password)
      @user_id = user_id
      @password = password
      @cookie_manager = CookieManager.new
      @request_manager = RequestManager.new
    end

    def authenticate
      cookies = request_manager.get_jsession_id
      cookies.each do |cookie_string|
        cookie_manager.push_cookie(cookie_string)
      end

      cookies = request_manager.login_sso_page(@user_id, @password, cookie_manager.cookies)
      cookies.each do |cookie_string|
        cookie_manager.push_cookie(cookie_string)
      end

      cookies = request_manager.redirect_to_classnet(cookie_manager.cookies)
      cookies.each do |cookie_string|
        cookie_manager.push_cookie(cookie_string)
      end

      cookies = request_manager.move_to_classnet_main(cookie_manager.cookies)
      cookies.each do |cookie_string|
        cookie_manager.push_cookie(cookie_string)
      end
    end

    def get_student_info
      return if cookie_manager.cookies.empty?

      information = request_manager.get_login_information(cookie_manager.cookies)
      information
    end
  end
end
