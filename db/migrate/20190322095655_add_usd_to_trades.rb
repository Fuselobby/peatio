class AddUsdToTrades < ActiveRecord::Migration
  def change
  	add_column :trades, :volume_usd, :decimal, precision: 32, scale: 16, after: :volume
  	add_column :trades, :funds_usd, :decimal, precision: 32, scale: 16, after: :funds
  end
end
