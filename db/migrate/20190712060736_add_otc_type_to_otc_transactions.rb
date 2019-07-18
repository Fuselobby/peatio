class AddOtcTypeToOtcTransactions < ActiveRecord::Migration
  def change
    add_column :otc_transactions, :otc_type, :string, null: false
  end
end
