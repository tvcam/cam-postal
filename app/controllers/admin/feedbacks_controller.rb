module Admin
  class FeedbacksController < BaseController
    def index
      @status = params[:status]
      @feedbacks = Feedback.recent

      @feedbacks = case @status
      when "unread"
                     @feedbacks.unread
      when "read"
                     @feedbacks.where.not(read_at: nil)
      else
                     @feedbacks
      end

      @total_count = Feedback.count
      @unread_count = Feedback.unread.count
    end

    def show
      @feedback = Feedback.find(params[:id])
      @feedback.update(read_at: Time.current) if @feedback.read_at.nil?
    end

    def destroy
      @feedback = Feedback.find(params[:id])
      @feedback.destroy!
      redirect_to admin_feedbacks_path(status: params[:status]), notice: "Feedback deleted"
    end
  end
end
