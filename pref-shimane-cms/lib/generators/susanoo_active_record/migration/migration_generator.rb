require 'rails/generators/active_record/migration/migration_generator'

module SusanooActiveRecord
  class MigrationGenerator < ActiveRecord::Generators::MigrationGenerator
    source_root File.expand_path('../templates', __FILE__)
  end
end
