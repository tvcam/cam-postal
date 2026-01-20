require "test_helper"

class PostalCodeTest < ActiveSupport::TestCase
  setup do
    # Ensure aliases are loaded fresh for each test
    PostalCode.reload_aliases!
  end

  test "reverse_aliases builds lookup from official name to aliases" do
    reverse = PostalCode.reverse_aliases

    assert_kind_of Hash, reverse
    # Preah Sihanouk has aliases like sihanoukville, snv, etc.
    assert_includes reverse["preah sihanouk"], "sihanoukville"
    assert_includes reverse["preah sihanouk"], "snv"
    # Kampot has aliases
    assert_includes reverse["kampot"], "kampot city"
    assert_includes reverse["kampot"], "kampot town"
  end

  test "reverse_aliases is case insensitive on keys" do
    reverse = PostalCode.reverse_aliases

    # Keys should be lowercase
    assert reverse.key?("preah sihanouk")
    refute reverse.key?("Preah Sihanouk")
  end

  test "aliases_for_location returns aliases for matching location" do
    postal_code = postal_codes(:sihanoukville_province)

    aliases = postal_code.aliases_for_location

    assert_kind_of Array, aliases
    assert_includes aliases, "sihanoukville"
    assert_includes aliases, "snv"
    assert_includes aliases, "kompong som"
  end

  test "aliases_for_location returns empty array when no aliases exist" do
    postal_code = postal_codes(:tuoltompong_commune)

    aliases = postal_code.aliases_for_location

    assert_kind_of Array, aliases
    assert_empty aliases
  end

  test "aliases_for_location is case insensitive" do
    # Chamkar Mon has aliases in the YAML
    postal_code = postal_codes(:chamkarmon_district)

    aliases = postal_code.aliases_for_location

    assert_includes aliases, "chamkar mon"
    assert_includes aliases, "chamkarmon"
  end

  test "reload_aliases clears both aliases and reverse_aliases cache" do
    # Access to populate cache
    PostalCode.aliases
    PostalCode.reverse_aliases

    # Reload should clear both
    PostalCode.reload_aliases!

    # Should still work after reload
    assert_kind_of Hash, PostalCode.aliases
    assert_kind_of Hash, PostalCode.reverse_aliases
  end
end
