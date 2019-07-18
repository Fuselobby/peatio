class CreateOtcTransaction < ActiveRecord::Migration
  def change
    create_table :otc_transactions do |t|
      t.references :member, index: true, foreign_key: true
      t.string :currency_pay, null: false
      t.string :currency_get, null: false
      t.string :destination_address, null: false
      t.decimal :price, default: 0.0, precision: 32, scale: 16, null: false
      t.decimal :exchange_fee, default: 0.0, precision: 17, scale: 16, null: false
      t.decimal :network_fee, default: 0.0, precision: 17, scale: 16, null: false
      t.decimal :volume, default: 0.0, precision: 32, scale: 16, null: false
      t.decimal :amount_pay, default: 0.0, precision: 32, scale: 16, null: false
      t.decimal :amount_get, default: 0.0, precision: 32, scale: 16, null: false

      t.timestamps null: false
    end
  end
end
