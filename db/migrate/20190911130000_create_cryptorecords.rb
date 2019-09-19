class CreateCryptorecords < ActiveRecord::Migration
  def change
    create_table :crypto_records do |t|
      t.string :crypto, null: true
      t.text :context, null: true
      t.string :lang, null: true
    end
  end
end

