class ChangeReferralCounts < ActiveRecord::Migration
  def change
    rename_column :members, :referral_counts, :referrals_count
  end
end
