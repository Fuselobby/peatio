class AddIndexToExtTrades < ActiveRecord::Migration
  def change
  	  add_index "ext_trades", ["ask_id"], name: "index_ext_trades_on_ask_id", using: :btree
	  add_index "ext_trades", ["ask_member_id", "bid_member_id"], name: "index_ext_trades_on_ask_member_id_and_bid_member_id", using: :btree
	  add_index "ext_trades", ["bid_id"], name: "index_ext_trades_on_bid_id", using: :btree
	  add_index "ext_trades", ["created_at"], name: "index_ext_trades_on_created_at", using: :btree
	  add_index "ext_trades", ["market_id", "created_at"], name: "index_ext_trades_on_market_id_and_created_at", using: :btree
  end
end
