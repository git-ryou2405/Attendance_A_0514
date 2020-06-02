class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month, :req_overtime, :update_overtime, :notice_overtime]
  before_action :logged_in_user, only: [:update, :edit_one_month, :req_overtime]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: [:edit_one_month, :req_overtime, :update_overtime, :notice_overtime, :update_notice_overtime]

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  NOTICE_ERROR_MSG = "入力が足りません。申請をやり直してください。"

  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_one_month
  end

  def update_one_month
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.attributes = item
        attendance.save!(context: :attendance_update)
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  def req_overtime
    @att_id = @user.attendances.find(params[:att_id].to_i)
    
    # 申請していなければ、デフォルト時間を00:00へ設定
    if @att_id.o_request.nil?
      @att_id.end_time = Time.current.change(year: @att_id.worked_on.year, month: @att_id.worked_on.month,
                                              day: @att_id.worked_on.day, hour: '0', min: '0', sec: '0')
      @att_id.save
    end
  end
  
  def update_overtime
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      req_overtime_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.attributes = item
        overtime_calc(attendance) # 残業時間の計算
        attendance.o_approval = '申請中'
        attendance.save!(context: :overtime_update)
        @worked_on = l(attendance.worked_on, format: :short)
        @o_request = attendance.o_request
      end
    end
    flash[:success] = "#{@worked_on}の残業申請を\"#{@o_request}\"へ送信しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = NOTICE_ERROR_MSG
    redirect_to user_url(@user)
  end
  
  def notice_overtime
    @notice_user = User.where(id: Attendance.where(o_request: @user.name, o_approval: "申請中").select(:user_id))
    @attendance_lists = Attendance.where(o_request: @user.name, o_approval: "申請中")
  end
  
  def update_notice_overtime
    @count = [0,0,0]
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      notice_overtime_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.attributes = item
        if attendance.change
          @count[0] = @count[0] + 1 if attendance.o_approval == "なし"
          @count[1] = @count[1] + 1 if attendance.o_approval == "承認"
          @count[2] = @count[2] + 1 if attendance.o_approval == "否認"
          attendance.save!
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

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end

    # 残業時間申請内容を扱います。
    def req_overtime_params
      params.require(:user).permit(attendances: [:end_time, :overtime, :nextday, :business_process, :o_request])[:attendances]
    end

    # 通知のあった残業時間申請の承認を扱います。
    def notice_overtime_params
      params.require(:user).permit(attendances: [:o_approval, :change])[:attendances]
    end
    
    # 残業時間の計算
    def overtime_calc(attendance)
      # 比較用指定勤務終了時間の作成
      plan_time = Time.local(attendance.end_time.year, attendance.end_time.month, attendance.end_time.day,
                      @user.designated_work_end_time.hour-9, @user.designated_work_end_time.min, 0)
      # タイムゾーンの修正
      plan_time.in_time_zone("Asia/Tokyo")
      
      if attendance.nextday.present?
        attendance.overtime = ((attendance.end_time.since(1.days) - plan_time) / 3600)
      else
        attendance.overtime = ((attendance.end_time - plan_time) / 3600)
      end
    end
    
    # beforeフィルター

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end
    end
end