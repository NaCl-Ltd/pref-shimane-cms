class ChangeColumnDefaultPublicToHelps < ActiveRecord::Migration
  def change
    change_column_default(:helps, :public, 0)
  end
end
