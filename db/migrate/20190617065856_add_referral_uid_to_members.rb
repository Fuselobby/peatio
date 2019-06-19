class AddReferralUidToMembers < ActiveRecord::Migration
  def change
    add_column :members, :referral_uid, :string, limit: 12
  end
end
