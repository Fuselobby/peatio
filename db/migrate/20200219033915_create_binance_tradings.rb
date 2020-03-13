class CreateBinanceTradings < ActiveRecord::Migration
  def change
    create_table :binance_tradings do |t|
      t.string :market, limit: 10, null: false 
      t.integer :trade_id, limit: 11, null: false
      t.string :user_uid, limit: 12, null: false
      t.integer :order_id, limit: 11, null: true
      t.string :tx_id, limit: 12, null: false
      t.datetime :tx_datetime, null: false
      t.decimal :ori_price, precision: 32, scale: 16, default: 0, null: false
      t.decimal :price, precision: 32, scale: 16, default: 0, null: false
      t.decimal :ori_volume, precision:32, scale: 16, default: 0, null: false
      t.decimal :ori_qty, precision: 32, scale: 16, default: 0, null: false
      t.decimal :exe_qty, precision: 32, scale: 16, default: 0, null: false
      t.decimal :cum_qty, precision: 32, scale: 16, default: 0, null: false
      t.string :status, limit:30, default: "matched", null: false
      t.string :time_in_force, limit: 10, null: true
      t.string :trading_type, limit: 30, default: "market"
      t.string :side, limit: 30, null: true
      t.timestamps null: false
    end
  end
end