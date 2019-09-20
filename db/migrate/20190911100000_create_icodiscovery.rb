class CreateIcodiscovery < ActiveRecord::Migration
  def change
    create_table :ico_discovery do |t|
      t.string :name, limit: 255, null: true
      t.string :longname, limit: 255, null: true
      t.string :altname, limit: 255, null: true
      t.boolean  "enabled", default: true, null: false
    end
  end
end
