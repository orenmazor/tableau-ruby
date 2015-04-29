require File.dirname(__FILE__) + '/test_helper'

class TestWorkbook < TableauTest
  def test_workbook_listing
    workbooks = @client.workbooks.all(user_id: @admin_user[:id])
    assert workbooks[:workbooks].count > 0
    assert workbooks[:pagination].keys() == [:page_number, :page_size, :total_available]
  end

  def test_workbook_find_by_name
    all_workbooks = @client.workbooks.all(user_id: @admin_user[:id])
    workbook = @client.workbooks.find(site_id: @client.site_id, workbook_id: all_workbooks[:workbooks].first[:id])
    assert workbook[:id]
  end

  def test_workbook_include_views
    all_workbooks = @client.workbooks.all(user_id: @admin_user[:id])
    workbook = @client.workbooks.find(site_id: @client.site_id, workbook_id: all_workbooks[:workbooks].first[:id], include_views: true)
    assert workbook[:id]
    assert workbook[:views]
  end

  def test_workbook_create_request
    project_id = @client.projects.all[:projects].first[:id]
    Faraday::RackBuilder.any_instance.expects(:build_response).with do |*args|
      req = args[1]
      assert_equal req.method, :post
      assert_equal req.path, "/api/2.0/sites/#{@client.site_id}/workbooks"
      assert_equal req.headers["Content-Type"], "multipart/mixed; boundary=\"boundary-string\""

      uploaded_file = req.body
    end.raises("dont care")

    err = assert_raises(RuntimeError) {
      @client.workbooks.create(admin_password: ENV["TABLEAU_ADMIN_PASSWORD"], admin_username: ENV['TABLEAU_ADMIN_USER'], workbook_name: "test", project_id: project_id, site_id: @client.site_id, file_path: Tempfile.new("superfly").path)
    }
    assert_equal err.message, "dont care"
  end

  def test_workbook_gets_created
    project_id = @client.projects.all[:projects].first[:id]
    result = @client.workbooks.create(admin_password: ENV['TABLEAU_ADMIN_PASSWORD'], admin_username: ENV['TABLEAU_ADMIN_USER'], project_id: project_id, workbook_name: "fooboy", site_id: @client.site_id, file_path: "/tmp/foo.twb")

    assert_equal 200, result, "tableau workbook creation returns 200"
  end
end
