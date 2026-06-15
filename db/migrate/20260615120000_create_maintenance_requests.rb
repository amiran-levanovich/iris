class CreateMaintenanceRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_requests do |t|
      t.references :room, null: false, foreign_key: true
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :category, null: false
      t.string :priority, null: false, default: "medium"
      t.string :status, null: false, default: "open"

      t.timestamps
    end

    # Serves active_for(room) and the housekeeping board's active-count rollup.
    add_index :maintenance_requests, [ :room_id, :status ]
  end
end
