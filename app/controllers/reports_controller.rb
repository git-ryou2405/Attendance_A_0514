class ReportsController < ApplicationController
  before_action :set_user, only: [:notice_report, :update_report]
  
  NOTICE_ERROR_MSG = "入力が足りません。申請をやり直してください。"
  
  def create
    first_day = Date.strptime(params[:first_day],'%Y-%m-%d')
    @user = User.find(params[:user_id])
    report = @user.reports.where(r_month: first_day.month.to_i, user_id: params[:user_id]).first
    if report.present?
      if report.update_attributes(report_params)
        flash[:success] = "#{first_day.month}月の月次申請先を\"#{report.r_request}\"へ変更しました。"
      else
        flash[:danger] = "月次申請は失敗しました。<br><li>" + report.errors.full_messages.join("</li><li>")
      end
    else
      report = @user.reports.create(report_params)
      report.r_month = first_day.month.to_i
      if report.save
        flash[:success] = "\"#{report.r_request}\"へ#{first_day.month}月の月次申請を送信しました。"
      else
        flash[:danger] = "月次申請は失敗しました。<br><li>" + report.errors.full_messages.join("</li><li>")
      end
    end
    redirect_to user_path(@user,date: first_day)
  end
  
  def notice_report
    @notice_user = User.where(id: Report.where(r_request: @user.name, r_approval: "申請中").select(:user_id))
    @report_lists = Report.where(r_request: @user.name, r_approval: "申請中")
  end
  
  def update_report
    @count = [0,0,0]
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      notice_report_params.each do |id,item|
        report = Report.find(id)
        report.attributes = item
        if report.change
          @count[0] = @count[0] + 1 if report.r_approval == "なし"
          @count[1] = @count[1] + 1 if report.r_approval == "承認"
          @count[2] = @count[2] + 1 if report.r_approval == "否認"
          report.save!
        end
      end
    end
    unless @count.sum == 0
      flash[:success] = "#{@count.sum}件の申請を更新しました。（なし：#{@count[0]}件、承諾：#{@count[1]}件、否認：#{@count[2]}件）"
    else
      flash[:warning] = "変更にチェックが無かった為、中止しました。"
    end
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = NOTICE_ERROR_MSG
    redirect_to user_url(@user)
  end
  
  private
    
    # 所属長承認申請内容を扱います。
    def report_params
      params.permit(:r_approval, :r_request, :user_id)
    end
    
    # 通知のあった所属長承認申請の承認を扱います。
    def notice_report_params
      params.require(:user).permit(reports: [:r_month, :r_approval, :change, :user_id])[:reports]
    end
end
