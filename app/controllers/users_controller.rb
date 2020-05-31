class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_basic_info_admin, :working_list]
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :edit_basic_info_admin, :working_list]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info, :edit_basic_info_admin, :working_list]
  before_action :set_one_month, only: :show
  before_action :correct_user_or_admin, only: :show
  before_action :show_admin_check, only: :show
  before_action :set_year_date, only: :show

  def index
    @users = query.paginate(page: params[:page], per_page: 20)
    @search = params[:user][:name] if !@search_value.nil?
  end

  def show
    @users = User.all
    @worked_sum = @attendances.where.not(started_at: nil).count
    @r_count = 0
    @a_count = 0
    @o_count = Attendance.where(o_request: @user.name, o_approval: "申請中").count
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to users_url
    else
      render :edit
    end
  end
  
  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end
  
  def edit_basic_info
  end

  def edit_basic_info_admin
  end

  def working_list
    @users = User.all
  end

  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br><li>" + @user.errors.full_messages.join("</li><li>")
    end
    redirect_to users_url
  end
  
  def import
    # fileはtmp(temporary)に自動で一時保存される
    if params[:file].presence
      @regist_check = User.import(params[:file])
      
      if @regist_check
        flash[:success] = "CSVファイルのインポートが完了しました。"
      else
        flash[:danger] = "更新できるデータがありませんでした。"
      end
    else
      flash[:danger] = "CSVファイルが選択されていません。"
    end
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password, :basic_work_time, :designated_work_start_time, :designated_work_end_time)
    end
    
    def basic_info_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password, :basic_work_time, :designated_work_start_time, :designated_work_end_time)
    end
    
    def query
      if params[:user].present? && params[:user][:name] != ""
        @search_value = User.where('name LIKE ?', "%#{params[:user][:name]}%")
      else
        User.all
      end
    end
end