require 'csv'

CSV.generate do |csv|
  csv_column_names = %w(日付 出社時間 退社時間)
  csv << csv_column_names
  @attendances.each do |attendance|
    
    @started_at = ""
    @finished_at = ""
    unless attendance.started_at.nil?
      @started_at = attendance.started_at.strftime("%H:%M")
    end
    unless attendance.finished_at.nil?
      @finished_at = attendance.finished_at.strftime("%H:%M")
    end
    
    column_values = [
      attendance.worked_on.strftime("%Y/%m/%d"),
      @started_at,
      @finished_at
    ]
    
    csv << column_values
  end
end