class AddDefaultValueToOtcRate < ActiveRecord::Migration
  def change
    change_column :currencies, :otc_rate, :decimal, default: 0.0
  end
end
