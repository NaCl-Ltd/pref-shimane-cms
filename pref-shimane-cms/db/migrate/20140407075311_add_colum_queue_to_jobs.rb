class AddColumQueueToJobs < ActiveRecord::Migration
  def change
    change_table :jobs do |t|
      t.integer :queue, default: 0
      t.index :queue
    end
  end
end
