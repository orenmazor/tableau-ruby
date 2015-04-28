module Tableau
  class Project

    def initialize(client)
      @client = client
    end

    def all
      resp = @client.conn.get "/api/2.0/sites/#{@client.site_id}/projects" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      projects = {projects: []}
      Nokogiri::XML(resp.body).css("tsResponse projects project").each do |s|
        projects[:projects] << {id: s["id"], name: s["name"]}
      end
      projects
    end

    def create(project)
      return { error: "site_id is missing." }.to_json unless project[:site_id]
      return { error: "name is missing." }.to_json unless project[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.project(
            name: project[:name],
            description: project[:description]
          )
        end
      end

      resp = @client.conn.post "/api/2.0/sites/#{project[:site_id]}/projects" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      if resp.status == 201
        {project: resp.body}.to_json
      else
        {error: resp.status}.to_json
      end
    end

    def update(project)
      return { error: "site_id is missing." }.to_json unless project[:site_id]
      return { error: "name is missing." }.to_json unless project[:name]

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.project(
            name: project[:name],
            description: project[:description]
          )
        end
      end

      resp = @client.conn.put "/api/2.0/sites/#{project[:site_id]}/projects/#{project[:project_id]}" do |req|
        req.body = builder.to_xml
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end
      if resp.status == 200
        {project: resp.body}.to_json
      else
        {error: resp.status}.to_json
      end
    end


    def delete(project)
      return { error: "site_id is missing." }.to_json unless project[:site_id]
      return { error: "project id is missing." }.to_json unless project[:id]

      resp = @client.conn.delete "/api/2.0/sites/#{project[:site_id]}/projects/#{project[:id]}" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      if resp.status == 204
        {success: 'Project successfully deleted.'}.to_json
      else
        {error: resp.status}.to_json
      end
    end

  end
end
