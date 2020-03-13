class CreateBinanceAccountInformations < ActiveRecord::Migration
  def change
    create_table :binance_account_informations do |t|
      t.string :asset, null: false
      t.decimal :free, null: false, default: 0, precision: 32, scale: 16
      t.string  :user_api, null: false
      t.timestamps null: false
    end
  end
end
