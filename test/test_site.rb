require File.dirname(__FILE__) + '/test_helper'

class TestSite < TableauTest
  def test_site_listing
    sites = @client.sites.all 
    assert sites[:sites].is_a? Array
  end
end
