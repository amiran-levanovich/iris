class AddInternalIdToReservations < ActiveRecord::Migration[8.1]
  # Lightweight accessor so the backfill doesn't run the app model's callbacks
  # or validations against rows that don't have a code yet.
  class MigrationReservation < ActiveRecord::Base
    self.table_name = "reservations"
  end

  def up
    add_column :reservations, :internal_id, :string

    used = MigrationReservation.pluck(:internal_id).compact.to_set
    MigrationReservation.where(internal_id: nil).find_each do |reservation|
      code = ReservationCode.generate until code && used.add?(code)
      reservation.update_columns(internal_id: code)
    end

    add_index :reservations, :internal_id, unique: true
    change_column_null :reservations, :internal_id, false
  end

  def down
    remove_column :reservations, :internal_id
  end
end
