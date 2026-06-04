require "test_helper"

class V2::ExplorerControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get v2_explorer_show_url
    assert_response :success
  end
end
