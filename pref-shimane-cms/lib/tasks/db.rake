require 'active_record'

namespace :db do
  # db タスクの設定を追加する
  task :load_config do
    ActiveRecord::Tasks::DatabaseTasks.fixtures_path = File.join Rails.root, 'spec', 'fixtures'
  end

  desc "upgrade db schema"
  task :upgrade => :environment do
    schema_info = "#{ActiveRecord::Base.table_name_prefix}schema_info#{ActiveRecord::Base.table_name_suffix}"
    if ActiveRecord::Base.connection.table_exists?(schema_info)
      ActiveRecord::Base.connection.drop_table(schema_info)
      ActiveRecord::SchemaMigration.create_table
      if ActiveRecord::SchemaMigration.count(:version) == 0
        puts 'upgrade db schema'
        ActiveRecord::SchemaMigration.create!(version: '00000000000001')
        Rake::Task['db:migrate'].invoke
      end
    end
  end
end
