class CreateCryptoinfos < ActiveRecord::Migration
  def change
    create_table :crypto_infos do |t|
      t.string :crypto, null: true
      t.text :context, null: true
    end
  end
end