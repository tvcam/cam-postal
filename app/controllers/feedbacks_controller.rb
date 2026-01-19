class FeedbacksController < ApplicationController
  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = Feedback.new(feedback_params)
    @feedback.ip_address = request.remote_ip
    @feedback.user_agent = request.user_agent

    if @feedback.save
      TelegramNotifierService.notify_new_feedback(@feedback)
      redirect_to feedback_thanks_path, notice: t("feedback.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thanks
  end

  private

  def feedback_params
    params.require(:feedback).permit(:name, :email, :message)
  end
end
