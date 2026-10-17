class AddResolutionSummaryToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :resolution_summary, :text
  end
end
