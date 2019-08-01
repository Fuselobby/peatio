class AddAskMemberUidAndBidMemberUidToTrades < ActiveRecord::Migration
  def change
    add_column :trades, :ask_member_uid, :string, limit: 12, null: false
    add_column :trades, :bid_member_uid, :string, limit: 12, null: false
  end
end
