class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  
  $days_of_the_week = %w{日 月 火 水 木 金 土}

  # beforeフィルター

  # paramsハッシュからユーザーを取得します。
  def set_user
    if User.where(id: params[:id]).present?
      @user = User.find(params[:id])
    else
      flash[:danger] = "ユーザーが存在しません。"
      redirect_to root_url
    end
  end
  
  # ログイン済みのユーザーか確認します。
  def logged_in_user
    store_location
    unless logged_in?
      flash[:danger] = "ログインしてください。"
      redirect_to login_url
    end
  end

  # アクセスしたユーザーが現在ログインしているユーザーか確認します。
  def correct_user
    redirect_to(root_url) unless current_user?(@user)
  end
  
  # システム管理権限所有かどうか判定します。
  def admin_user
    unless current_user.admin?
      flash[:danger] = "権限がありません。(1)"
      redirect_to root_url
    end
  end
  
  # システム管理権限所有かどうか判定します。
  def show_admin_check
    @admin_check = User.find(params[:id])
    if @admin_check.admin?
      unless current_user.admin?
        flash[:danger] = "権限がありません。(2)"
        redirect_to root_url
      end
    end
  end

  # アクセスしたユーザーが
  # 現在ログインしているユーザーまたはシステム管理者権限所有か確認します。
  def correct_user_or_admin
    unless current_user?(@user) || current_user.admin? || current_user.superior?
      flash[:danger] = "権限がありません。(3)"
      redirect_to root_url
    end
  end
  
  # 所属長承認申請のために12ヶ月分のデータの存在を確認・セットします。
  def set_year_date
    @requests = @user.requests.where(r_month: 1..12)
    unless 12 == @requests.count
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、12ヶ月分の勤怠承認申請データを生成します。
        12.times { |n| @user.requests.create!(r_month: n+1) }
      end
      @requests = @user.requests.where(r_month: 1..12).order(:r_month)
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
  end

  # ページ出力前に1ヶ月分のデー���の存在を確認・セットします。
  def set_one_month
    @first_day = params[:date].nil? ?
      Date.current.beginning_of_month : params[:date].to_date
      
    @last_day = @first_day.end_of_month
    one_month = [*@first_day..@last_day] # 対象の月の日数を代入します。
    
    # ユーザーに紐付く一ヶ月分のレコードを検索して取得し、orderにて昇順に並び替えを行います。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    
    unless one_month.count == @attendances.count # それぞれの件数（日数）が一致するか評価します。
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
        one_month.each {|day| @user.attendances.create!(worked_on: day) }
      end
      @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗しました、再アクセスしてください。"
    redirect_to root_url
  end
  
end
