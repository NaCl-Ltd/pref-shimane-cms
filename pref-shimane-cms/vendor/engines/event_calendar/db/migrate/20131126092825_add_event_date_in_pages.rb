class AddEventDateInPages < ActiveRecord::Migration
  def change
    add_column :pages, :begin_event_date, :date
    add_column :pages, :end_event_date, :date
  end
end
