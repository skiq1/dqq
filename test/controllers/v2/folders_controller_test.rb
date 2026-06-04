require "test_helper"

class V2::FoldersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get v2_folders_index_url
    assert_response :success
  end

  test "should get show" do
    get v2_folders_show_url
    assert_response :success
  end

  test "should get new" do
    get v2_folders_new_url
    assert_response :success
  end

  test "should get create" do
    get v2_folders_create_url
    assert_response :success
  end

  test "should get edit" do
    get v2_folders_edit_url
    assert_response :success
  end

  test "should get update" do
    get v2_folders_update_url
    assert_response :success
  end

  test "should get destroy" do
    get v2_folders_destroy_url
    assert_response :success
  end
end
