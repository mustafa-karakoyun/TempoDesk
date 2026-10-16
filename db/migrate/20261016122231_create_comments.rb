class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :ticket, null: false, foreign_key: true
      t.integer :author_role, null: false
      t.string :author_name, null: false
      t.text :body, null: false

      t.timestamps
    end
  end
end
