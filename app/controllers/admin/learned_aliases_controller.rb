module Admin
  class LearnedAliasesController < BaseController
    def index
      @status = params[:status]
      @sort = params[:sort] || "clicks"
      @order = params[:order] || "desc"

      @learned_aliases = base_scope
      @learned_aliases = apply_status_filter(@learned_aliases)
      @learned_aliases = apply_sorting(@learned_aliases)

      # Stats
      @total_count = LearnedAlias.count
      @promoted_count = LearnedAlias.promoted.count
      @pending_count = LearnedAlias.pending.count
      @avg_click_rate = LearnedAlias.average_click_rate
    end

    def promote
      @learned_alias = LearnedAlias.find(params[:id])
      @learned_alias.update!(promoted: true)
      redirect_to admin_learned_aliases_path(filter_params), notice: "Alias promoted successfully"
    end

    def demote
      @learned_alias = LearnedAlias.find(params[:id])
      @learned_alias.update!(promoted: false)
      redirect_to admin_learned_aliases_path(filter_params), notice: "Alias demoted successfully"
    end

    def destroy
      @learned_alias = LearnedAlias.find(params[:id])
      @learned_alias.destroy!
      redirect_to admin_learned_aliases_path(filter_params), notice: "Alias deleted successfully"
    end

    private

    def base_scope
      LearnedAlias.includes(:postal_code_record)
    end

    def apply_status_filter(scope)
      case @status
      when "promoted"
        scope.promoted
      when "pending"
        scope.pending
      else
        scope
      end
    end

    def apply_sorting(scope)
      direction = @order == "asc" ? :asc : :desc

      case @sort
      when "rate"
        scope.order_by_rate(direction)
      when "searches"
        scope.order(search_count: direction)
      when "term"
        scope.order(search_term: direction)
      else
        scope.order(click_count: direction)
      end
    end

    def filter_params
      params.permit(:status, :sort, :order).to_h.compact_blank
    end
  end
end
