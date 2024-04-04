class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.string :job_id
      t.belongs_to :event, null: false, foreign_key: true
      t.belongs_to :member, null: false, foreign_key: true

      t.timestamps
    end
  end
end
