# frozen_string_literal: true

require 'net/http'

require 'hongik_sso/entrypoints'

module HongikSso
  class RequestManager
    include Entrypoints

    attr_accessor :request

    def initialize
      @request = {}
    end

    def get_jsession_id
      uri = URI "http://www.hongik.ac.kr/login.do"
      res = Net::HTTP.get_response(uri)
      cookies = res.get_fields('Set-Cookie').map { |cookie_str| cookie_str.split(';')[0] }

      cookies
    end

    def login_sso_page(user_id, password, cookies = [])
      uri = URI SSO_LOGIN_URL
      @request = Net::HTTP::Post.new(uri)

      setup_header

      @request["Origin"] = "http://www.hongik.ac.kr"
      @request["Referer"] = "http://www.hongik.ac.kr/login.do?Refer=#{CLASSNET_URL}"
      @request["Cookie"] = cookies.join(';')
      @request.set_form_data(
        "USER_ID" => user_id,
        "PASSWD" => password
      )

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      cookies_group = response.body.scan(/(SetCookie\(.*\)\;)/)
      new_cookies = cookies_group.map do |pattern|
        /SetCookie\(\'(?<name>.*)\',\s*\'(?<value>.*)\',\s*\d,\s*\'\.hongik\.ac\.kr\'\)/ =~ pattern.to_s
        "#{name}=#{value}"
      end

      new_cookies
    end

    def redirect_to_classnet(cookies = [])
      uri = URI CLASSNET_URL

      @request = Net::HTTP::Get.new(uri)

      setup_header
      @request["Origin"] = "http://www.hongik.ac.kr"
      @request["Referer"] = "http://www.hongik.ac.kr/login.do?Refer=#{CLASSNET_URL}"
      @request["Cookie"] = cookies.join(';')

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      cookie_string = response.get_fields('Set-Cookie')
      /(?<key>SUSER_EXTAUTH)\=(?<value>[0-9a-zA-Z]+)\;/ =~ cookie_string.to_s

      ["#{key}=#{value}"]
    end

    def move_to_classnet_main(cookies = [])
      uri = URI "#{CLASSNET_URL}/stud/"

      @request = Net::HTTP::Get.new(uri)

      setup_header
      @request["Origin"] = "#{CLASSNET_URL}/stud"
      @request["Referer"] = SSO_LOGIN_URL
      @request["Cookie"] = cookies.join(';')

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      cookie_string = response.get_fields('Set-Cookie')
      /(?<key>WMONID)\=(?<value>[0-9a-zA-Z]+)\;/ =~ cookie_string.to_s

      ["#{key}=#{value}"]
    end

    def get_login_information(cookies = [])
      uri = URI	"#{CLASSNET_URL}/stud/include/header.jsp"

      @request = Net::HTTP::Get.new(uri)

      setup_header
      @request["Origin"] = "#{CLASSNET_URL}/stud"
      @request["Referer"] = "#{CLASSNET_URL}/stud/frame.jsp"
      @request["Cookie"] = cookies.join(';')

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      /\<span\sclass\="user_name"\>\s+(?<student_name>.+)\s+\[(?<student_id>[A-Z]\d{6})\]\s*.+\s*\<\/span\>/ =~ response.body
      ec = Encoding::Converter.new("EUC-KR", "UTF-8")

      {
        student_name: ec.convert(student_name),
        student_id: student_id.to_s
      }
    end

    private

    def setup_header
      @request.content_type = "application/x-www-form-urlencoded"
      @request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64; rv:81.0) Gecko/20100101 Firefox/81.0"
      @request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
      @request["Accept-Language"] = "ko-KR,en-US;q=0.7,en;q=0.3"

      @request["Connection"] = "keep-alive"
      @request["Upgrade-Insecure-Requests"] = "1"
    end
  end
end