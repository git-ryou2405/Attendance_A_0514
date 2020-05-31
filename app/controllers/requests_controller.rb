class RequestsController < ApplicationController
  before_action :set_user, only: :update
  before_action :set_year_date, only: :update
  
  def update
    @request = Request.where(r_month: params[:month], user_id: params[:id]).first
    
    if @request.update(req_params)
      @request.r_approval = "申請中"
      @request.save
      flash[:success] = "申請しました。"
    else
      flash[:danger] = "申請は失敗しました。<br><li>" + @request.errors.full_messages.join("</li><li>")
    end
    redirect_to user_path(@user)
  end
  
    # 残業時間申請内容を扱います。
  def req_params
    params.require(:request).permit(:r_request)
  end
end
