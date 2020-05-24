class BasesController < ApplicationController
  before_action :set_base, only: [:edit, :update, :destroy]
  
  def new
  end
  
  def edit
  end
  
  def index
    @base = Base.all
  end
  
  def create
    @base = Base.create(base_params)
    if @base.update_attributes(base_params)
      flash[:success] = "#{@base.base_name}の拠点情報が追加されました。"
      redirect_to bases_url
    else
      flash[:danger] = "拠点情報を追加できませんでした。<br><li>" + @base.errors.full_messages.join("</li><li>")
      redirect_to bases_url
    end
  end
  
  def update
    @base_name = @base.base_name
    if @base.update_attributes(base_params)
      flash[:success] = "#{@base.base_name}の拠点情報を更新しました。"
      redirect_to bases_path
    else
      flash[:success] = "#{@base_name}の更新は失敗しました。<br><li>" + @base.errors.full_messages.join("</li><li>")
      redirect_to bases_path
    end
  end
  
  def destroy
    @basename = @base.base_name
    @base.destroy
    flash[:success] = "#{@basename}拠点の削除が完了しました。"
    redirect_to bases_path
  end
  
  def set_base
    @base = Base.find(params[:id])
  end
  
  private

    def base_params
      params.require(:base).permit(:base_no, :base_name, :attendance_type)
    end
end
