class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.integer :amount_cents, null: false
      t.string :merchant, null: false
      t.string :category, null: false
      t.text :description, null: false
      t.date :spent_on, null: false
      t.string :submitted_by, null: false
      t.integer :status, default: 0, null: false
      t.integer :approver_role, null: false
      t.datetime :review_due_at, null: false
      t.string :verdict
      t.integer :risk_score
      t.string :policy_clause
      t.text :llm_reason
      t.string :decided_by
      t.datetime :decided_at

      t.timestamps
    end
  end
end
