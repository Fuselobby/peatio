class CreateExtTrades < ActiveRecord::Migration
  def change
    create_table :ext_trades do |t|
      t.decimal :price, precision: 32, scale: 16
      t.decimal :volume, precision: 32, scale: 16
      t.integer :ask_id
      t.integer :bid_id
      t.integer :trend
      t.string :market_id, limit: 20
      t.integer :ask_member_id
      t.integer :bid_member_id
      t.decimal :funds, precision: 32, scale: 16

      t.timestamps null: false
      
      t.string :ask_member_uid, limit: 12
      t.string :bid_member_uid, limit: 12
    end
  end
end
