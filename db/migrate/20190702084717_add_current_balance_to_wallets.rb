class AddCurrentBalanceToWallets < ActiveRecord::Migration
  def change
    add_column :wallets, :current_balance, :decimal, default: 0.00, null: false, precision: 32, scale: 16, after: :max_balance
  end
end
