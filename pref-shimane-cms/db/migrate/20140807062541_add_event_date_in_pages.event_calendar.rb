# This migration comes from event_calendar (originally 20131126092825)
class AddEventDateInPages < ActiveRecord::Migration
  def change
    add_column :pages, :begin_event_date, :date
    add_column :pages, :end_event_date, :date
  end
end
