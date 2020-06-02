class CreateReports < ActiveRecord::Migration[5.1]
  def change
    create_table :reports do |t|
      t.integer :r_month
      t.string :r_approval
      t.string :r_request
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
