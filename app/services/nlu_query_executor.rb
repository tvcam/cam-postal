class NluQueryExecutor
  attr_reader :intent, :context

  def initialize(intent)
    @intent = intent.deep_symbolize_keys
    @context = {}
  end

  def execute
    return { results: [], context: {} } unless valid_intent?

    case intent[:intent]
    when "search_location"
      execute_search_location
    when "list_by_parent"
      execute_list_by_parent
    when "search_landmark"
      execute_search_landmark
    when "search_nearby"
      execute_search_nearby
    else
      { results: [], context: {} }
    end
  end

  def self.execute(intent)
    new(intent).execute
  end

  private

  def valid_intent?
    return false unless intent[:intent].present?
    return false if intent[:confidence].to_f < 0.7
    true
  end

  def execute_search_location
    name = intent[:location_name]
    type = intent[:location_type]

    return { results: [], context: {} } unless name.present?

    results = PostalCode.search(name)

    # Filter by type if specified
    if type.present? && results.any?
      filtered = results.select { |r| r.location_type == type }
      results = filtered if filtered.any?
    end

    @context = {
      action: :search_location,
      search_term: name,
      location_type: type
    }

    { results: results, context: @context }
  end

  def execute_list_by_parent
    parent_name = intent[:parent_name]
    child_type = intent[:location_type]

    return { results: [], context: {} } unless parent_name.present?

    # Find the parent location
    parent = find_parent_location(parent_name)
    return { results: [], context: {} } unless parent

    # Get children of the appropriate type
    results = get_children(parent, child_type)

    @context = {
      action: :list_by_parent,
      parent_name: parent.name_en,
      parent_code: parent.postal_code,
      child_type: child_type || infer_child_type(parent)
    }

    { results: results, context: @context }
  end

  def execute_search_landmark
    landmark = intent[:landmark]
    return { results: [], context: {} } unless landmark.present?

    # Check aliases first (landmarks are typically in aliases)
    resolved = PostalCode.resolve_alias(landmark)

    if resolved != landmark
      # Found an alias, search for the resolved name
      results = PostalCode.search(resolved)
      @context = {
        action: :search_landmark,
        landmark: landmark,
        resolved_to: resolved
      }
    else
      # No alias, try direct search
      results = PostalCode.search(landmark)
      @context = {
        action: :search_landmark,
        landmark: landmark
      }
    end

    { results: results, context: @context }
  end

  def execute_search_nearby
    # For "nearby" queries, find the reference location and return siblings
    location_name = intent[:location_name] || intent[:landmark]
    return { results: [], context: {} } unless location_name.present?

    # Find the reference location
    ref_results = PostalCode.search(location_name)
    reference = ref_results.first
    return { results: [], context: {} } unless reference

    # Get siblings (same parent)
    results = case reference.location_type
    when "commune"
      PostalCode.communes
                .where("postal_code LIKE ?", "#{reference.postal_code[0, 4]}%")
                .where.not(id: reference.id)
                .order(:name_en)
                .limit(20)
    when "district"
      PostalCode.districts
                .where("postal_code LIKE ?", "#{reference.postal_code[0, 2]}%")
                .where.not(id: reference.id)
                .order(:name_en)
                .limit(20)
    else
      PostalCode.provinces.where.not(id: reference.id).order(:name_en).limit(10)
    end

    @context = {
      action: :search_nearby,
      reference: reference.name_en,
      reference_code: reference.postal_code
    }

    { results: [ reference ] + results.to_a, context: @context }
  end

  def find_parent_location(name)
    # Try to find as province first
    results = PostalCode.search(name)
    return nil if results.empty?

    # Prefer provinces for "list_by_parent" queries
    province = results.find(&:province?)
    return province if province

    # Otherwise use first match (could be district)
    results.first
  end

  def get_children(parent, child_type)
    case parent.location_type
    when "province"
      if child_type == "commune"
        PostalCode.communes
                  .where("postal_code LIKE ?", "#{parent.postal_code[0, 2]}%")
                  .order(:name_en)
                  .limit(50)
      else
        # Default to districts
        PostalCode.districts
                  .where("postal_code LIKE ?", "#{parent.postal_code[0, 2]}%")
                  .order(:name_en)
                  .limit(50)
      end
    when "district"
      PostalCode.communes
                .where("postal_code LIKE ?", "#{parent.postal_code[0, 4]}%")
                .order(:name_en)
                .limit(50)
    else
      []
    end
  end

  def infer_child_type(parent)
    case parent.location_type
    when "province" then "district"
    when "district" then "commune"
    else nil
    end
  end
end
