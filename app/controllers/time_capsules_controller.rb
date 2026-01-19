class TimeCapsulesController < ApplicationController
  before_action :set_postal_code, only: :create
  before_action :set_time_capsule, only: [ :heart, :flag ]

  def create
    unless TimeCapsule.can_create?(request.remote_ip)
      return respond_with_error(t("time_capsules.rate_limited"))
    end

    @time_capsule = @postal_code.time_capsules.build(capsule_params)
    @time_capsule.ip_hash = TimeCapsule.hash_ip(request.remote_ip)

    if @time_capsule.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("capsules-list", partial: "time_capsules/capsule", locals: { capsule: @time_capsule }),
            turbo_stream.update("capsule-form", partial: "time_capsules/form_success"),
            turbo_stream.update("capsules-count", partial: "time_capsules/count", locals: { count: @postal_code.time_capsules.visible.count })
          ]
        end
        format.html { redirect_to postal_code_path(@postal_code.postal_code), notice: t("time_capsules.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("capsule-form", partial: "time_capsules/form", locals: {
            postal_code: @postal_code,
            time_capsule: @time_capsule
          })
        end
        format.html { redirect_to postal_code_path(@postal_code.postal_code), alert: @time_capsule.errors.full_messages.first }
      end
    end
  end

  def heart
    if @time_capsule.hearted_by?(request.remote_ip)
      @time_capsule.remove_heart!(request.remote_ip)
      hearted = false
    else
      @time_capsule.add_heart!(request.remote_ip)
      hearted = true
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "capsule-#{@time_capsule.id}-heart",
          partial: "time_capsules/heart_button",
          locals: { capsule: @time_capsule, hearted: hearted }
        )
      end
      format.json { render json: { hearts_count: @time_capsule.hearts_count, hearted: hearted } }
    end
  end

  def flag
    @time_capsule.update(flagged: true)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("capsule-#{@time_capsule.id}")
      end
      format.json { render json: { success: true } }
    end
  end

  private

  def set_postal_code
    @postal_code = PostalCode.find_by!(postal_code: params[:postal_code])
  end

  def set_time_capsule
    @time_capsule = TimeCapsule.find(params[:id])
  end

  def capsule_params
    params.require(:time_capsule).permit(:message, :mood, :nickname, :visible_at)
  end

  def respond_with_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("capsule-form-error", html: message)
      end
      format.html { redirect_to postal_code_path(@postal_code.postal_code), alert: message }
      format.json { render json: { error: message }, status: :too_many_requests }
    end
  end
end
