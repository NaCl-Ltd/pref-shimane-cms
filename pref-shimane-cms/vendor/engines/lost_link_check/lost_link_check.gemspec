$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "lost_link_check/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "lost_link_check"
  s.version     = LostLinkCheck::VERSION
  s.authors     = ["Network Applied Communication Laboratory Ltd."]
  s.email       = ["webmaster@netlab.jp"]
  s.homepage    = "http://www.netlab.jp/"
  s.summary     = "Lost Link Check Engine."
  s.description = "lost_link_check provide checking lost links in page contents"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "4.0.2"
  s.add_dependency "pg", "0.17.1"
  s.add_dependency "sdoc"
  s.add_dependency "kaminari", "0.15.0"
  s.add_dependency "acts_as_tree", "1.5.0"
  s.add_dependency "acts_as_list", "0.3.0"
  s.add_dependency "rails_config", "0.3.3"
  s.add_dependency "ckeditor", "4.0.8"
  s.add_dependency "paperclip", "3.5.2"
  s.add_dependency "iconv", "1.0.4"
  s.add_dependency "nokogiri", "1.6.1"
  s.add_dependency "twitter-bootstrap-rails", "2.2.8"
  s.add_dependency "activerecord-session_store", "0.1.0"
  s.add_dependency "mail-iso-2022-jp", "2.0.2"
  s.add_dependency "rspec-rails", "2.14.1"
  s.add_dependency "shoulda-matchers", "2.4.0"
  s.add_dependency "factory_girl_rails", "4.3.0"
  s.add_dependency "database_cleaner", "1.2.0"
  s.add_dependency "capybara", "2.2.1"
  s.add_dependency "timecop", "0.7.1"
end
