class AddAddressToGuests < ActiveRecord::Migration[8.1]
  def change
    add_column :guests, :street, :string
    add_column :guests, :city, :string
    add_column :guests, :postal_code, :string
    add_column :guests, :country, :string
  end
end
