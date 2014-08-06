require 'active_record'

namespace :pref_shimane_cms do

  desc "show pref-shimane-cms version"
  task version: :environment do
    puts PrefShimaneCms::Application::VERSION
  end
end
