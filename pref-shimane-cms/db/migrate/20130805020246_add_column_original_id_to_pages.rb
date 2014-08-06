class AddColumnOriginalIdToPages < ActiveRecord::Migration
  def change
    add_column :pages, :original_id, :integer
  end
end
