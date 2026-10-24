class CreateExpenseEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :expense_events do |t|
      t.references :expense, null: false, foreign_key: true
      t.string :actor, null: false
      t.string :action, null: false
      t.text :reason

      t.timestamps
    end
  end
end
