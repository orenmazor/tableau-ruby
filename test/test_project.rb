require File.dirname(__FILE__) + '/test_helper'

class TestProjects < TableauTest
  def test_project_listing
    all_projects = @client.projects.all
    assert all_projects[:projects].is_a? Array
    assert all_projects[:projects].size() > 0
  end
end
