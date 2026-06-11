class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.references :property, null: false, foreign_key: true
      t.string :number, null: false
      t.string :room_type, null: false
      t.integer :capacity, null: false
      t.integer :nightly_rate_cents, null: false, default: 0
      t.string :status, null: false, default: "operational"
      t.integer :floor
      t.text :description

      t.timestamps

      t.index [ :property_id, :number ], unique: true
    end
  end
end
