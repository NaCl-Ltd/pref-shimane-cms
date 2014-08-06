$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "import_page/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "import_page"
  s.version     = ImportPage::VERSION
  s.authors     = ["Network Applied Communication Laboratory Ltd."]
  s.email       = ["webmaster@netlab.jp"]
  s.homepage    = "http://www.netlab.jp/"
  s.summary     = "Import Page Engine."
  s.description = "import_page provide importing pages to cms"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rubyzip", "1.1.0"
end
