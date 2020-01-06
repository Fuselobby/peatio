class AddDateAndLinkToNotices < ActiveRecord::Migration
  def change
  	add_column :notices, :notice_date, :datetime, null: true
  	add_column :notices, :notice_url, :string, null: true
  end
end
