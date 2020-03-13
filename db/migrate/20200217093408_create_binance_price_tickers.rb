class CreateBinancePriceTickers < ActiveRecord::Migration
  def change
    create_table :binance_price_tickers do |t|
      t.string :symbol, null: false
      t.decimal :price, null: false, default: 0, precision: 32, scale: 16
      t.timestamps null: false
    end
  end
end
