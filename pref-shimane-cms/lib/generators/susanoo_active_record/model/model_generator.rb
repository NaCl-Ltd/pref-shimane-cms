require 'rails/generators/active_record/model/model_generator'

module SusanooActiveRecord
  class ModelGenerator < ActiveRecord::Generators::ModelGenerator
    source_root File.expand_path('../templates', __FILE__)

    def create_concerns_file
      template 'concerns/association.rb', File.join('app/models/concerns', class_path, file_name, "association.rb")
      template 'concerns/method.rb', File.join('app/models/concerns', class_path, file_name, "method.rb")
      template 'concerns/validation.rb', File.join('app/models/concerns', class_path, file_name, "validation.rb")
    end
  end
end
