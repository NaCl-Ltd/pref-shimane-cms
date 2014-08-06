class AddEventFolderTypeInGenres < ActiveRecord::Migration
  def change
    add_column :genres, :event_folder_type, :integer, :default => ::Genre.event_folder_types[:none]
  end
end
