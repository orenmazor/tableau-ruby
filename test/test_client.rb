require "minitest/autorun"
require 'tableau_ruby'
require 'mocha/setup'

class TestClient < Minitest::Test
  def test_client_sets_up_connection
    Tableau::Client.any_instance.expects(:setup_connection)
    Tableau::Client.any_instance.expects(:sign_in)
    Tableau::Client.any_instance.expects(:get_site_id)

    Tableau::Client.new(host: 'http://www.zombo.com', admin_name: 'bar', admin_password: 'waldo')
  end
end
