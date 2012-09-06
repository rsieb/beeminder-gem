# coding: utf-8

module Beeminder
  class User
    # @return [String] User name.
    attr_reader :name

    # @return [String] Auth token.
    attr_reader :token

    # @return [DateTime] Last time user made any changes.
    attr_reader :updated_at

    # @return [String] Timezone.
    attr_reader :timezone
    
    def initialize name, token
      @name  = name
      @token = token

      info = get "users/#{@name}.json"
      
      @timezone   = info["Timezone"]
      @updated_at = DateTime.strptime(info["updated_at"].to_s, '%s')
    end

    # List of goals.
    #
    # @param filter [Symbol] filter goals, can be `:all` (default), `:frontburner` or `:backburner`
    # @ return [Array<Beeminder::Goal>] returns list of goals
    def goals filter=:all
      raise "invalid goal filter: #{filter}" unless [:all, :frontburner, :backburner].include? filter

      info = get "users/#{@name}.json", :filter => filter.to_s
      goals = info["goals"].map do |goal|
        Beeminder::Goal.new self, goal
      end unless info["goals"].nil?

      goals || []
    end

    # Create new goal.
    def create_goal
    end

    # Send GET request to API.
    #
    # @param cmd [String] the API command, like `users/#{user.name}.json`
    # @param data [Hash] data to send; auth_token is included by default (optional)
    def get cmd, data={}
      _connection :get, cmd, data
    end

    # Send POST request to API.
    #
    # @param cmd [String] the API command, like `users/#{user.name}.json`
    # @param data [Hash] data to send; auth_token is included by default (optional)
    def post cmd, data={}
      _connection :post, cmd, data
    end

    private

    # Establish HTTPS connection to API.
    def _connection type, cmd, data
      api  = "https://www.beeminder.com/api/v1/#{cmd}"
      data = {"auth_token" => @token}.merge(data)
      
      url = URI.parse(api)
      http = Net::HTTP.new(url.host, url.port)
      http.read_timeout = 8640
      http.use_ssl = true

      json = ""
      http.start do |http|
        req = case type
              when :post
                req = Net::HTTP::Post.new(url.path)
              when :get
                req = Net::HTTP::Get.new(url.path)
              else
                raise "invalid connection type"
              end
        req.set_form_data(data)
        res = http.request(req)
        if not res.is_a? Net::HTTPSuccess
          raise "request failed: #{res.body}"
        end

        json = res.body
      end

      # parse json
      json = JSON.load(json)

      json
    end
  end
end
