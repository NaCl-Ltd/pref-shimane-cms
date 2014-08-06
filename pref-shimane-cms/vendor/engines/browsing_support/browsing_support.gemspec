$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "browsing_support/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "browsing_support"
  s.version     = BrowsingSupport::VERSION
  s.authors     = ["Network Applied Communication Laboratory Ltd."]
  s.email       = ["webmaster@netlab.jp"]
  s.homepage    = "http://www.netlab.jp/"
  s.summary     = "Browsing Support Engine"
  s.description = "browsing_support provide giving kana to site and reading site"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "natto", "0.9.6"
end
