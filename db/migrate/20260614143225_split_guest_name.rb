class SplitGuestName < ActiveRecord::Migration[8.1]
  # Lightweight accessor so the data backfill doesn't depend on the app model
  # (which now validates first_name/last_name and would reject the old rows).
  class MigrationGuest < ActiveRecord::Base
    self.table_name = "guests"
  end

  def up
    add_column :guests, :first_name, :string
    add_column :guests, :last_name, :string

    MigrationGuest.reset_column_information
    MigrationGuest.find_each do |guest|
      first, last = guest.name.to_s.strip.split(" ", 2)
      guest.update_columns(first_name: first.presence || guest.name, last_name: last)
    end

    remove_column :guests, :name
  end

  def down
    add_column :guests, :name, :string

    MigrationGuest.reset_column_information
    MigrationGuest.find_each do |guest|
      guest.update_columns(name: [ guest.first_name, guest.last_name ].compact_blank.join(" "))
    end

    remove_column :guests, :first_name
    remove_column :guests, :last_name
  end
end
