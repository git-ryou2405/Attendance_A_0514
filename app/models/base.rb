class Base < ApplicationRecord
  validates :base_no, presence: true, length: { maximum: 4 }
  validates :base_name, presence: true, length: { maximum: 10 }
  validates :attendance_type, presence: true
  
end
