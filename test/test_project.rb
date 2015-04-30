require File.dirname(__FILE__) + '/test_helper'

class TestProjects < TableauTest
  def test_project_create_find_and_delete
    mytest = "orentest#{Time.now.to_i}"
    result_id = @client.projects.create(name: mytest, description: "test what do you want from me")
    assert result_id

    project_id = @client.projects.find_by(name: mytest)[:id]
    assert_equal project_id, result_id

    assert @client.projects.delete(id: project_id)
  end

  def test_project_listing
    all_projects = @client.projects.all
    assert all_projects[:projects].is_a? Array
    assert all_projects[:projects].size() > 0
  end
end
