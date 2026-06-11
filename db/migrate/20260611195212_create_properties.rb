class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :street
      t.string :city
      t.string :postal_code
      t.string :country
      t.text :description
      t.integer :stars

      t.timestamps
    end
  end
end
