module AdminHelper
  def sort_link(label, column)
    current_sort = params[:sort] || "clicks"
    current_order = params[:order] || "desc"

    new_order = (current_sort == column && current_order == "desc") ? "asc" : "desc"
    is_active = current_sort == column

    arrow = if is_active
              current_order == "desc" ? " &#9660;" : " &#9650;"
    else
              ""
    end

    link_to(
      "#{label}#{arrow}".html_safe,
      url_for(sort: column, order: new_order, status: params[:status]),
      class: "sort-link #{is_active ? 'active' : ''}"
    )
  end
end
