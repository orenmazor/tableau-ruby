module Tableau
  class Users

    attr_reader :workbooks

    def initialize(client)
      @client = client
    end

    def create(options)
      site_id = options[:site_id] || @client.site_id

      return { error: "name is missing." }.to_json unless options[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.user(
            name: options[:name],
            siteRole: "Interactor"
          )
        end
      end

      resp = @client.conn.post "/api/2.0/sites/#{site_id}/users" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      raise resp.body if resp.status > 299

      Nokogiri::XML(resp.body).css("tsResponse user").each do |s|
        return s["id"]
      end
    end

    def all(params={})
      site_id = @client.site_id

      resp = @client.conn.get "/api/2.0/sites/#{site_id}/users?pageSize=#{params["page-size"]}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {users: []}
      Nokogiri::XML(resp.body).css("tsResponse users user").each do |u|
        data[:users] << {
          id: u['id'],
          name: u['name'],
          site_id: site_id,
          role: u['role'],
          publish: u['publish'],
          content_admin: u['contentAdmin'],
          last_login: u['lastLogin'],
          external_auth_user_id: u['externalAuthUserId']
        }
      end
      data
    end

    def find_by(params={})
      params.update({"page-size" => 1000})

      #BUG: if you have more than 1000 users, you wont find your users
      #needs pagination support
      all_users = all(params)[:users]

      if params[:id]
        return all_users.select {|u| u[:id] == params[:id] }.first
      elsif params[:name]
        return all_users.select {|u| u[:name] == params[:name] }.first
      else
        raise "You need :id or :name"
      end
    end


    private

    def normalize_json(r, site_id, name=nil)
      data = {user: {}}
      Nokogiri::XML(r).css("user").each do |u|
        data[:user] = {
          id: u['id'],
          name: u['name'],
          site_id: site_id,
          role: u['role'],
          publish: u['publish'],
          content_admin: u['contentAdmin'],
          last_login: u['lastLogin'],
          external_auth_user_id: u['externalAuthUserId']
        }
        return data.to_json if !name.nil? && name == u['name']
      end
      data.to_json
    end

  end
end
