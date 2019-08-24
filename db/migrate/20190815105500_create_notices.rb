class CreateNotices < ActiveRecord::Migration
  def change
    create_table :notices do |t|
      t.string :notice_title, null: false
      t.text :description, limit:2000, null: true
      t.boolean  "enabled", default: true, null: false
      t.datetime :from_date, null: true
      t.datetime :to_date, null: true

      t.timestamp  :created_at, null: false
    end
  end
end
