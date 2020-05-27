class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month, :req_overtime, :update_overtime, :notice_overtime]
  before_action :logged_in_user, only: [:update, :edit_one_month, :req_overtime]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: [:edit_one_month, :req_overtime, :update_overtime]

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

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
    @day = @user.attendances.find(params[:day].to_i)
    
    # 申請していなければ、デフォルト時間を00:00へ設定
    if @day.o_request.nil?
      @day.end_time = Time.current.change(year: @day.worked_on.year, month: @day.worked_on.month, day: @day.worked_on.day, hour: '0', min: '0', sec: '0')
      @day.save
    end
  end
  
  def update_overtime
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      req_overtime_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.attributes = item
        attendance.save!(context: :overtime_update)
        @worked_on = l(attendance.worked_on, format: :short)
        @o_request = attendance.o_request
        
      end
    end
    flash[:success] = "#{@worked_on}の残業申請を\"#{@o_request}\"へ送信しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "入力が足りません。申請をやり直してください。"
    redirect_to user_url(@user)
  end
  
  def notice_overtime
    @current_user = @user
    req_overtime_count
  end
  
  def update_notice_overtime
  end

  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end

    # 1ヶ月分の勤怠情報を扱います。
    def req_overtime_params
      params.require(:user).permit(attendances: [:end_time, :nextday, :business_process, :o_request])[:attendances]
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
    
    def req_overtime_count
      @users = User.all
      @users.each do |user|
        user.attendances.each do |attendance|
          if attendance.o_request == @user.name
            
            @req_attendance = attendance
            @req_attendance.o_reqcount =+ 1
            @req_attendance.save
          end
        end
      end
    end
    
end