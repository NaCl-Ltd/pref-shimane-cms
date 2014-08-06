# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

PrefShimaneCms::Application.load_tasks

require 'rdoc/task'
require 'sdoc'

Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options << '-m'  << 'doc/development.rdoc'
  rdoc.options << '-e'  << 'UTF-8'
  rdoc.options << '-f'  << 'sdoc'
  rdoc.options << '-T'  << 'rails'
  rdoc.title    = ENV['title'] || "PrefShimaneCms Documentation"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('doc/development.rdoc')
  rdoc.rdoc_files.include('app/**/*.rb')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
