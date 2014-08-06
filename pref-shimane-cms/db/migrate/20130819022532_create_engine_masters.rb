class CreateEngineMasters < ActiveRecord::Migration
  def change
    create_table :engine_masters do |t|
      t.string :name
      t.boolean :enable, default: false
    end
  end
end
