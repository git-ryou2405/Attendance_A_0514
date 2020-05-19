class CreateBases < ActiveRecord::Migration[5.1]
  def change
    create_table :bases do |t|
      t.integer :base_no
      t.string :base_name
      t.string :attendance_type

      t.timestamps
    end
  end
end
