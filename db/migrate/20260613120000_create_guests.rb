class CreateGuests < ActiveRecord::Migration[8.1]
  def change
    create_table :guests do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone

      t.timestamps
    end

    add_index :guests, :email, unique: true, where: "email IS NOT NULL"
  end
end
