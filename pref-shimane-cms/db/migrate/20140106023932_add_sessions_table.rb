class AddSessionsTable < ActiveRecord::Migration
  def change
    #
    # 旧CMSからアップグレードする場合は、すでに sessions テーブルがあるので
    # sessions テーブルを作成しない
    #
    unless ActiveRecord::Base.connection.table_exists?('sessions')
      create_table :sessions do |t|
        t.string :session_id, :null => false
        t.text :data
        t.datetime :updated_at
      end
      add_index :sessions, :session_id, :unique => true
    end
  end
end
