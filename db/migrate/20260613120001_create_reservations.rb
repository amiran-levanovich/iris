class CreateReservations < ActiveRecord::Migration[8.1]
  def change
    create_table :reservations do |t|
      t.references :guest, null: false, foreign_key: true
      t.references :room, null: false, foreign_key: true
      t.date :check_in_on, null: false
      t.date :check_out_on, null: false
      t.integer :nightly_rate_cents, null: false
      t.string :status, null: false, default: "booked"

      t.timestamps
    end

    add_index :reservations, [ :room_id, :check_in_on ]
    add_index :reservations, :status
  end
end
