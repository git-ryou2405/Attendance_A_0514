class Attendance < ApplicationRecord
  belongs_to :user
  
  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }
  
# 残業申請のバリデーション
  validates :o_request, presence: true, on: :overtime_update
  validates :business_process, presence: true, on: :overtime_update
  
  # 出勤時間が存在しない場合、残業時間は無効
  validate :end_time_at_is_invalid_without_a_started_at, on: :overtime_update
  
  # 翌日=falseの場合、出社時間より早い終了予定時間は無効
  validate :started_at_than_end_time_fast_if_invalid, on: :overtime_update
  
  def end_time_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が入力されていません") if started_at.blank? && end_time.present?
  end
  
  def started_at_than_end_time_fast_if_invalid
    errors.add(:started_at, "より早い終了予定時間は無効です") if started_at > end_time && o_nextday == false
  end
  
# 勤怠変更申請のバリデーション
  # 必要なアイテム検証
  validate :need_item, on: :attendance_update
  
  # 出社・退社時間どちらも存在し、翌日=falseの場合、出社時間より早い退社時間は無効
  validate :started_at_than_finished_at_fast_if_invalid, on: :attendance_update
  
  # 在社時間が24時間オーバーチェック
  validate :total_working_over24h, on: :attendance_update
    
  def need_item
    errors.add(:started_at, "の入力が不足しています") if c_af_finished_at.blank?
    errors.add(:finished_at, "の入力が不足しています") if c_af_started_at.blank?
    errors.add(:note, "の入力が不足しています") if note.blank?
  end
  
  def started_at_than_finished_at_fast_if_invalid
    if c_af_started_at.present? && c_af_finished_at.present? && c_nextday == false
      errors.add(:started_at, "より早い退勤時間は無効です") if c_af_started_at > c_af_finished_at
    end
  end
  
  def total_working_over24h
    if c_af_started_at.present? && c_af_finished_at.present? && c_nextday == true
      @total = ((c_af_finished_at.since(1.days) - c_af_started_at) / 3600)
      errors.add(:company_time, "が24時間をオーバーしてしまいます") unless @total < 24
    end
  end
  
end
