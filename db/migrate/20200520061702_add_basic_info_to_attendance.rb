class AddBasicInfoToAttendance < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :o_approval, :string
    add_column :attendances, :o_request, :string
    add_column :attendances, :end_time, :datetime, default: Time.current.change(hour: 0, min: 0, sec: 0)
    add_column :attendances, :business_process, :string
    add_column :attendances, :nextday, :boolean, default: false
    add_column :attendances, :change, :boolean, default: false
  end
end
