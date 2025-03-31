require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  setup do
    @post = posts(:one)
  end

  test "visiting the index" do
    visit posts_url
    assert_selector "h1", text: "Posts"
  end

  test "should create post" do
    visit posts_url
    click_on "New Post"

    fill_in "Description", with: @post.description
    fill_in "Slug", with: @post.slug
    select @post.status, from: "Status"
    fill_in "Title", with: @post.title
    fill_in "Username", with: users(:one).username
    click_on "Create Post"

    assert_text "Post was successfully created"
    click_on "Back"
  end

  # test "should update Post" do
  #   # Log in as a user who can update posts
  #   visit new_user_session_path
  #   fill_in "Email", with: users(:one).email
  #   fill_in "Password", with: "1234567890" # Replace with the correct password
  #   click_on "Log in"

  #   visit post_url(@post)
  #   click_on "Edit this post", match: :first

  #   fill_in "Description", with: @post.description
  #   fill_in "Slug", with: @post.slug
  #   select @post.status, from: "Status"
  #   fill_in "Title", with: @post.title
  #   click_on "Update Post"

  #   assert_text "Post was successfully updated"
  #   click_on "Back"
  # end

  test "should destroy Post" do
    # Log in as a user who can destroy posts
    visit new_user_session_path
    fill_in "Email", with: users(:one).email
    fill_in "Password", with: "1234567890" # Replace with the correct password
    click_on "Log in"

    visit post_url(@post)
    click_on "Destroy this post", match: :first

    page.driver.browser.switch_to.alert.accept

    assert_text "Post was successfully destroyed"
  end
end
