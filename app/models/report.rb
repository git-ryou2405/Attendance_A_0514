class Report < ApplicationRecord
  belongs_to :user
  
  validates :r_request,  presence: true
end
