class CreateBinanceWithdrawals < ActiveRecord::Migration
  def change
    create_table :binance_withdrawals do |t|
      t.string :msg, null: true
      t.string :success, null: false
      t.string :tx_id, null: true
      t.string :binance_withdraw_id, null: false
      t.integer :released, null: false, default: 0, limit: 1
      t.timestamps null: false
    end
  end
end
