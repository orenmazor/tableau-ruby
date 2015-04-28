require File.dirname(__FILE__) + '/test_helper'

class TestSite < Minitest::Test
  def setup
    @client = Tableau::Client.new(host: ENV['TABLEAU_URL'], admin_name: ENV['TABLEAU_ADMIN_USER'], admin_password: ENV['TABLEAU_ADMIN_PASSWORD'])
  end

  def test_site_listing
    sites = @client.sites.all 
    assert sites[:sites].is_a? Array
  end
end
