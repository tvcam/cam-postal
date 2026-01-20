require "test_helper"

class SurpriseControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get surprise_url
    assert_response :success
    assert_select "h1", /Surprise/i
  end

  test "should get index and show categories" do
    get surprise_url
    assert_response :success
    assert_select ".category-btn"
    assert_select ".surprise-btn"
  end

  test "should get reveal with beach category and show destiny card" do
    # Beach category includes Preah Sihanouk (18) and Kampot (07)
    get surprise_reveal_url, params: { category: "beach" }
    assert_response :success
    assert_select ".destiny-card"
    assert_select ".destiny-name"
    assert_select ".destiny-emoji"
  end

  test "should get reveal with foodie category" do
    # Foodie category includes Kampot (07)
    get surprise_reveal_url, params: { category: "foodie" }
    assert_response :success
    assert_select ".destiny-card"
  end

  test "should get reveal with temple category" do
    # Temple category includes Siem Reap (17)
    get surprise_reveal_url, params: { category: "temple" }
    assert_response :success
    assert_select ".destiny-card"
  end

  test "should get reveal with city category" do
    # City category includes Phnom Penh (12)
    get surprise_reveal_url, params: { category: "city" }
    assert_response :success
    assert_select ".destiny-card"
  end

  test "should get reveal as turbo stream with beach category" do
    get surprise_reveal_url, params: { category: "beach" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/turbo-stream/, response.body)
    assert_match(/destiny-card/, response.body)
  end

  test "reveal redirects when no destination found for unknown category" do
    # Use a category that has no provinces in fixtures
    get surprise_reveal_url, params: { category: "nonexistent" }
    # Should redirect back to surprise page when no results
    assert_response :redirect
    assert_redirected_to surprise_path
  end
end
