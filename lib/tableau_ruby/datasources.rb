
require 'base64'
require 'securerandom'

module Tableau
  class Datasources

    def initialize(client)
      @client = client
    end

    def create(params = {})
      params[:site_id] ||= @client.site_id
      params[:admin_password] ||= ENV['TABLEAU_ADMIN_PASSWORD']
      params[:admin_username] ||= ENV['TABLEAU_ADMIN_USER']

      raise "Missing datasource file!" unless params[:file_path]
      raise "Missing site-id" unless params[:site_id]
      raise "Missing project id" unless params[:project_id]
      raise "Missing admin password" unless params[:admin_password]
      raise "Missing admin username" unless params[:admin_username]

      filename = params[:file_path].split("/").last

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.tsRequest do
          xml.datasource(name: filename.gsub(".tds","")) do
            xml.project(id: params[:project_id])
          end
        end
      end

      payload = builder.doc.root.to_xml#(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML)
      multipart_body = <<-BODY
--boundary-string
Content-Disposition: name="request_payload"
Content-Type: text/xml

#{payload}
--boundary-string
Content-Disposition: name="tableau_datasource"; filename="#{filename}"
Content-Type: application/octet-stream

#{File.read(params[:file_path])}
--boundary-string--
BODY

      multipart_body.gsub!("\n","\r\n")

      resp = @client.conn.post("/api/2.0/sites/#{params[:site_id]}/datasources") do |req|
        req.params["overwrite"] = true
        req.headers["Content-Type"] = "multipart/mixed; boundary=\"boundary-string\""
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
        req.body = multipart_body
      end
     
      raise resp.body if resp.status > 299

      true
    end

    def all(params={})
      resp = @client.conn.get "/api/2.0/sites/#{@client.site_id}/datasources?pageSize=1000" do |req|
        req.headers['X-Tableau-Auth'] = @client.token if @client.token
      end

      data = {datasources: [], pagination: {}}
      doc = Nokogiri::XML(resp.body)

      doc.css("pagination").each do |p|
        data[:pagination][:page_number] = p['pageNumber']
        data[:pagination][:page_size] = p['pageSize']
        data[:pagination][:total_available] = p['totalAvailable']
      end

      doc.css("datasource").each do |w|
        workbook = {id: w["id"], name: w["name"], type: w['type']}

        w.css('project').each do |p|
          workbook[:project] = {id: p['id'], name: p['name']}
        end

        w.css("tag").each do |t|
          (workbook[:tags] ||=[]) << t['id']
        end

        data[:datasources] << workbook
      end
      data
    end

    def find(params)

      all_ds = all

      if params[:name]
        return all_ds[:datasources].select {|x| x[:name] == params[:name]}.first
      elsif params[:id]
        return all_ds[:datasources].select {|x| x[:id] == params[:id]}.first
      end
    end
  end
end
