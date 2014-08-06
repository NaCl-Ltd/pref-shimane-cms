require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

class Rails::SusanooControllerGenerator < Rails::Generators::ScaffoldControllerGenerator
  source_root File.expand_path('../templates', __FILE__)

  def create_concerns_file
    template 'concerns/controller.rb', File.join('app/controllers/concerns', class_path, "#{controller_file_name}_controller.rb")
  end
end
