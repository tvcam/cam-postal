require "test_helper"

class LearnedAliasTest < ActiveSupport::TestCase
  setup do
    # Clear any existing learned aliases
    LearnedAlias.delete_all
  end

  test "record_search increments search_count for existing records" do
    LearnedAlias.create!(search_term: "test", postal_code: "120101", search_count: 5)

    LearnedAlias.record_search("test")

    assert_equal 6, LearnedAlias.find_by(search_term: "test").search_count
  end

  test "record_search normalizes search term to lowercase" do
    LearnedAlias.create!(search_term: "test", postal_code: "120101", search_count: 0)

    LearnedAlias.record_search("TEST")
    LearnedAlias.record_search("Test")

    assert_equal 2, LearnedAlias.find_by(search_term: "test").search_count
  end

  test "record_search ignores blank terms" do
    LearnedAlias.record_search("")
    LearnedAlias.record_search(nil)
    LearnedAlias.record_search("a") # too short

    assert_equal 0, LearnedAlias.count
  end

  test "record_click creates new record if not exists" do
    assert_difference "LearnedAlias.count", 1 do
      LearnedAlias.record_click("russian market", "120307")
    end

    record = LearnedAlias.find_by(search_term: "russian market")
    assert_equal "120307", record.postal_code
    assert_equal 1, record.click_count
    assert_not_nil record.last_clicked_at
  end

  test "record_click increments click_count for existing record" do
    LearnedAlias.create!(search_term: "bkk", postal_code: "120101", click_count: 5)

    LearnedAlias.record_click("bkk", "120101")

    assert_equal 6, LearnedAlias.find_by(search_term: "bkk").click_count
  end

  test "record_click normalizes search term to lowercase" do
    LearnedAlias.record_click("BKK", "120101")
    LearnedAlias.record_click("Bkk", "120101")
    LearnedAlias.record_click("bkk", "120101")

    assert_equal 1, LearnedAlias.count
    assert_equal 3, LearnedAlias.first.click_count
  end

  test "record_click ignores blank inputs" do
    LearnedAlias.record_click("", "120101")
    LearnedAlias.record_click("test", "")
    LearnedAlias.record_click(nil, "120101")

    assert_equal 0, LearnedAlias.count
  end

  test "click_rate calculates correctly" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 12,
      search_count: 20
    )

    assert_equal 0.6, record.click_rate
  end

  test "click_rate returns 0 when search_count is zero" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 10,
      search_count: 0
    )

    assert_equal 0, record.click_rate
  end

  test "meets_promotion_criteria returns true when all thresholds met" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 12,
      search_count: 20,  # click_rate = 0.6 (60%)
      unique_ips: 8
    )

    assert record.meets_promotion_criteria?
  end

  test "meets_promotion_criteria returns false when click_count too low" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 5,  # below MIN_CLICKS (10)
      search_count: 8,
      unique_ips: 5
    )

    assert_not record.meets_promotion_criteria?
  end

  test "meets_promotion_criteria returns false when click_rate too low" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 10,
      search_count: 20,  # click_rate = 0.5, below 0.6
      unique_ips: 5
    )

    assert_not record.meets_promotion_criteria?
  end

  test "meets_promotion_criteria returns false when unique_ips too low" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 12,
      search_count: 20,
      unique_ips: 3  # below MIN_UNIQUE_IPS (5)
    )

    assert_not record.meets_promotion_criteria?
  end

  test "check_promotion promotes when criteria met" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 15,
      search_count: 20,  # click_rate = 0.75 (75%)
      unique_ips: 8,
      promoted: false
    )

    record.check_promotion!

    assert record.reload.promoted?
  end

  test "check_promotion does not demote already promoted" do
    record = LearnedAlias.create!(
      search_term: "test",
      postal_code: "120101",
      click_count: 1,  # below threshold
      search_count: 1,
      unique_ips: 1,
      promoted: true  # already promoted
    )

    record.check_promotion!

    assert record.reload.promoted?  # stays promoted
  end

  test "promoted_aliases returns hash of promoted aliases" do
    LearnedAlias.create!(search_term: "bkk", postal_code: "120101", promoted: true)
    LearnedAlias.create!(search_term: "russian", postal_code: "120307", promoted: true)
    LearnedAlias.create!(search_term: "pending", postal_code: "120000", promoted: false)

    result = LearnedAlias.promoted_aliases

    assert_equal({ "bkk" => "120101", "russian" => "120307" }, result)
  end

  test "resolve returns location name for promoted alias" do
    # Create a postal code first
    postal_code = PostalCode.find_by(postal_code: "120101") ||
                  PostalCode.create!(postal_code: "120101", name_en: "Test Location", location_type: "commune")

    LearnedAlias.create!(search_term: "test alias", postal_code: "120101", promoted: true)

    result = LearnedAlias.resolve("test alias")

    assert_equal postal_code.name_en, result
  end

  test "resolve returns nil for non-promoted alias" do
    LearnedAlias.create!(search_term: "pending", postal_code: "120101", promoted: false)

    result = LearnedAlias.resolve("pending")

    assert_nil result
  end

  test "resolve returns nil for unknown term" do
    result = LearnedAlias.resolve("unknown")

    assert_nil result
  end

  test "scopes work correctly" do
    promoted = LearnedAlias.create!(search_term: "p1", postal_code: "120101", promoted: true)
    pending = LearnedAlias.create!(search_term: "p2", postal_code: "120102", promoted: false)

    assert_includes LearnedAlias.promoted, promoted
    assert_not_includes LearnedAlias.promoted, pending

    assert_includes LearnedAlias.pending, pending
    assert_not_includes LearnedAlias.pending, promoted
  end
end
