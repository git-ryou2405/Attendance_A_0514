class AddBasicInfoToAttendance < ActiveRecord::Migration[5.1]
  def change
    
    # 勤怠変更申請
    add_column :attendances, :c_approval, :string
    add_column :attendances, :c_request, :string
    add_column :attendances, :c_approval_date, :date
    add_column :attendances, :c_bf_started_at, :datetime
    add_column :attendances, :c_bf_finished_at, :datetime
    add_column :attendances, :c_af_started_at, :datetime
    add_column :attendances, :c_af_finished_at, :datetime
    add_column :attendances, :c_bf_nextday, :boolean, default: false
    add_column :attendances, :c_af_nextday, :boolean, default: false
    
    # 残業申請
    add_column :attendances, :o_approval, :string
    add_column :attendances, :o_request, :string
    add_column :attendances, :o_nextday, :boolean, default: false
    add_column :attendances, :end_time, :datetime
    add_column :attendances, :overtime, :float
    add_column :attendances, :business_process, :string
    
    # 共通カラム（勤怠変更申請＆残業申請）
    add_column :attendances, :change, :boolean, default: false
  end
end
