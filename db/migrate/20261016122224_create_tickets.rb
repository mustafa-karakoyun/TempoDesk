class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.string :customer_email, null: false
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.datetime :due_at, null: false
      t.datetime :solved_at
      t.string :access_token, null: false

      t.timestamps
    end

    add_index :tickets, :access_token, unique: true
  end
end
