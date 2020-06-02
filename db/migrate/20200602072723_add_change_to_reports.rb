class AddChangeToReports < ActiveRecord::Migration[5.1]
  def change
    add_column :reports, :change, :boolean, default: false
  end
end
