class AddOtcRateToCurrencies < ActiveRecord::Migration
  def change
    add_column :currencies, :otc_rate, :decimal, precision: 17, scale: 16
  end
end
