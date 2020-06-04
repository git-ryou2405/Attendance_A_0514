class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month, :req_overtime, :update_overtime, :notice_overtime, :update_notice_overtime, :notice_change_at, :update_notice_change_at]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: [:edit_one_month]

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  NOTICE_ERROR_MSG = "入力が足りません。申請をやり直してください。"
  
  # 出退勤ボタン
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      unless @attendance.c_approval == "申請中"
        if @attendance.update_attributes(started_at: Time.current.change(sec: 0),
                                        c_started_at: Time.current.change(sec: 0))
          flash[:info] = "おはようございます！"
        else
          flash[:danger] = UPDATE_ERROR_MSG + @attendance.errors.full_messages.join
        end
      else
        if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
          flash[:info] = "おはようございます！"
        else
          flash[:danger] = UPDATE_ERROR_MSG + @attendance.errors.full_messages.join
        end
      end
    elsif @attendance.finished_at.nil?
      unless @attendance.c_approval == "申請中"
        if @attendance.update_attributes(finished_at: Time.current.change(sec: 0),
                                        c_finished_at: Time.current.change(sec: 0))
          flash[:info] = "お疲れ様でした。"
        else
          flash[:danger] = UPDATE_ERROR_MSG
        end
      else
        if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
          flash[:info] = "お疲れ様でした。"
        else
          flash[:danger] = UPDATE_ERROR_MSG
        end
      end
    end
    redirect_to @user
  end
  
  # 勤怠編集画面
  def edit_one_month
  end

  # 勤怠変更申請の送信
  def update_one_month
    @count = 0 # 申請完了カウンター
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        @attendance = Attendance.find(id)
        @attendance.attributes = item
        # 現在日以前のみ確認
        if @attendance.worked_on <= Date.current
          # 申請先が選択済み、既に申請中でないもの
          if @attendance.c_request.present? && @attendance.c_approval != "申請中"
            @attendance.c_started_at = make_time(@attendance, "start")
            @attendance.c_finished_at = make_time(@attendance, "finish")
            @attendance.c_approval = "申請中"
            if @attendance.save!(context: :attendance_update)
              @count += 1
            end
          end
        end
      end
    end
    
    if @count > 0
      flash[:success] = "勤怠情報の編集申請を#{@count}件送信しました。"
      redirect_to user_url(date: params[:date])
    else
      flash[:warning] = "申請先が未選択です。"
      redirect_to attendances_edit_one_month_user_url(date: params[:date])
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "<li>" + @attendance.errors.full_messages.join("</li><li>")
    redirect_to attendances_edit_one_month_user_url(date: params[:date])
  end
  
  # 勤怠変更申請のお知らせフォーム
  def notice_change_at
    @notice_user = User.where(id: Attendance.where(c_request: @user.name, c_approval: "申請中").select(:user_id))
    @attendance_lists = Attendance.where(c_request: @user.name, c_approval: "申請中")
  end
  
  # 勤怠変更申請のお知らせフォーム＊承認状態の変更
  def update_notice_change_at
    @count = [0,0,0]
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      notice_change_at_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.attributes = item
        if attendance.change && attendance.c_approval != "申請中"
          if attendance.c_approval == "承認"
            # 変更前が存在する場合は置き換える
            attendance.started_at = attendance.c_started_at
            attendance.finished_at = attendance.c_finished_at
            attendance.o_nextday = true if attendance.c_nextday
            attendance.c_request = nil
            if attendance.save!
              @count[0] += 1
            end
          else
            attendance.note = nil
            attendance.c_nextday = false
            # 変更前が存在する場合は置き換える
            attendance.c_started_at = attendance.started_at
            attendance.c_finished_at = attendance.finished_at
            attendance.c_request = nil
            attendance.change = false
            if attendance.save!
              @count[1] += 1 if attendance.c_approval == "否認"
              @count[2] += 1 if attendance.c_approval == "なし"
            end
          end
        end
      end
    end
    unless @count.sum == 0
      flash[:success] = "#{@count.sum}件の申請を更新しました。（承諾：#{@count[0]}件、否認：#{@count[1]}件、なし：#{@count[2]}件）"
    else
      flash[:warning] = "更新できる申請がありません。"
    end
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = NOTICE_ERROR_MSG
    redirect_to user_url(@user)
  end
  
  # 残業申請フォーム
  def req_overtime
    @att_id = @user.attendances.find(params[:att_id].to_i)
    
    # 申請していなければ、デフォルト時間を00:00へ設定
    if @att_id.o_request.nil?
      @att_id.end_time = Time.current.change(year: @att_id.worked_on.year, month: @att_id.worked_on.month,
                                              day: @att_id.worked_on.day, hour: '0', min: '0', sec: '0')
      @att_id.save
    end
  end
  
  # 残業申請の送信
  def update_overtime
    @total = 0
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      req_overtime_params.each do |id, item|
        @attendance = Attendance.find(id)
        @attendance.attributes = item
        # 残業時間の計算
        if @attendance.started_at.blank?
          @started_nil = true
        else
          @total = overtime_calc(@attendance)
          if @total <= 24
            @attendance.o_approval = '申請中'
            @attendance.save!(context: :overtime_update)
            @worked_on = l(@attendance.worked_on, format: :short)
            @o_request = @attendance.o_request
          end
        end
      end
    end
    if @started_nil
      flash[:danger] = "出社時間が入力されていません。"
    elsif @total <= 24
      flash[:success] = "#{@worked_on}の残業申請を\"#{@o_request}\"へ送信しました。"
    else
      flash[:danger] = "在社時間が24時間をオーバーしてしまいます。"
    end
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = @attendance.errors.full_messages.join
    redirect_to user_url(@user)
  end
  
  # 残業申請のお知らせフォーム
  def notice_overtime
    @notice_user = User.where(id: Attendance.where(o_request: @user.name, o_approval: "申請中").select(:user_id))
    @attendance_lists = Attendance.where(o_request: @user.name, o_approval: "申請中")
  end
  
  # 残業申請のお知らせフォーム＊承認状態の変更
  def update_notice_overtime
    @count = [0,0,0]
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      notice_overtime_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.attributes = item
        if attendance.change && attendance.o_approval != "申請中"
          if attendance.o_approval == "承認"
            attendance.finished_at = attendance.end_time
            attendance.c_finished_at = attendance.end_time
            attendance.c_nextday = true if attendance.o_nextday
            if attendance.save!
              @count[0] += 1
            end
          else
            attendance.end_time = nil
            attendance.overtime = nil
            attendance.o_request = nil
            attendance.o_nextday = false
            attendance.business_process = nil
            if attendance.save!
              @count[1] += 1 if attendance.o_approval == "否認"
              @count[2] += 1 if attendance.o_approval == "なし"
            end
          end
        end
      end
    end
    unless @count.sum == 0
      flash[:success] = "#{@count.sum}件の申請を更新しました。（承諾：#{@count[0]}件、否認：#{@count[1]}件、なし：#{@count[2]}件）"
    else
      flash[:warning] = "変更にチェックが無かった為、中止しました。"
    end
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = NOTICE_ERROR_MSG
    redirect_to user_url(@user)
  end

  private

    # 勤怠変更申請内容を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:c_started_at, :c_finished_at, :c_nextday, :c_request, :note])[:attendances]
    end
    
    # 通知のあった勤怠変更申請の承認内容を扱います。
    def notice_change_at_params
      params.require(:user).permit(attendances: [:c_approval, :change])[:attendances]
    end

    # 残業時間申請内容を扱います。
    def req_overtime_params
      params.require(:user).permit(attendances: [:end_time, :overtime, :o_nextday, :business_process, :o_request])[:attendances]
    end

    # 通知のあった残業時間申請の承認内容を扱います。
    def notice_overtime_params
      params.require(:user).permit(attendances: [:o_approval, :change])[:attendances]
    end
    
    # 残業時間の計算
    def overtime_calc(at)
      # 比較計算用 指定勤務終了時間の作成
      @work_end_time = (Time.local(at.end_time.year,
                              at.end_time.month,
                              at.end_time.day,
                              @user.designated_work_end_time.hour,
                              @user.designated_work_end_time.min,
                              0).in_time_zone("Asia/Tokyo") - 9.hour).floor_to(15.minutes) 
      
      @work_start_time = (Time.local(at.end_time.year,
                              at.end_time.month,
                              at.end_time.day,
                              @user.designated_work_start_time.hour,
                              @user.designated_work_start_time.min,
                              0).in_time_zone("Asia/Tokyo") - 9.hour).floor_to(15.minutes) 
      
      # 指定勤務開始時間より早く出社してた場合
      @over = 0
      if @work_start_time > at.started_at
        @start = at.started_at.floor_to(15.minutes) 
        @over = (@work_start_time - @start)
      end
      
      # 残業時間 & 在社時間の計算（翌日チェック判定）
      if at.o_nextday.present?
        @end = at.end_time.since(1.days).floor_to(15.minutes) 
        at.overtime = (((@end - @work_end_time) + @over) / 3600)
        t1 = ((at.end_time.since(1.days) - at.started_at) / 3600)
      else
        @end = at.end_time.floor_to(15.minutes) 
        at.overtime = (((@end - @work_end_time) + @over) / 3600)
        t2 = ((at.started_at - at.end_time) / 3600)
      end
      total = t1 != nil ? t1 : t2
      return total
    end
    
    # 日付が未設定なため日付の設定
    def make_time(at, hours)
      hours = hours == "start" ? at.c_started_at : at.c_finished_at
      
      @datetime = DateTime.new(at.worked_on.year,
                              at.worked_on.month,
                              at.worked_on.day,
                              hours.hour,
                              hours.min,
                              0).in_time_zone("Asia/Tokyo") - 9.hour
      return @datetime
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