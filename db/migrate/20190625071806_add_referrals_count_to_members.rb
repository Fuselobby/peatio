class AddReferralsCountToMembers < ActiveRecord::Migration
  def change
    add_column :members, :referral_counts, :integer, default: 0
  end
end
