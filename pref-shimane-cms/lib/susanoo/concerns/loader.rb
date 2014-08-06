#
#=== モデル Concern を動的に include するモジュール
#  
#  以下のように本モジュールをincludeすることで、concernsが自動的に include されます
#
#  class SampleModel < ActiveRecord::Base
#   include Susanoo::Concerns::Loader
#  end
#
module Susanoo::Concerns::Loader
  extend ActiveSupport::Concern

  included do
    __filename = self.name.split("::").map {|c| c.downcase }.join('/')
    __class_ancestors = self.ancestors

    __concerns_path = if __class_ancestors.include?(ActiveRecord::Base)
      "app/models"
    elsif __class_ancestors.include?(ActionController::Base)
      "app/controllers"
    else
      "lib"
    end

    # モジュールの検索先となるメインアプリとエンジンのパスを設定する
    __engines_root = File.join(Rails.root, "vendor/engines")
    __concern_find_roots = [Rails.root.to_s]
    Rails::Application::Railties.engines.each do |e|
      if e.config.root.to_s =~ /^#{__engines_root}/
        __concern_find_roots << e.config.root.to_s
      end
    end
      
    # ロードするモジュールを検索する
    __concern_module_files  = []
    __concern_find_roots.each do |r|
      __concern_find_root = File.join(r, __concerns_path, "concerns", __filename)
      __concern_module_files += Pathname.glob("#{__concern_find_root}/*.rb")
    end

    __concern_module_files.each do |f|
      require f.to_s unless $".include?(f.to_s)
      m = f.basename.to_s.gsub(".rb", "").titleize.gsub(" ","")
      __concern_module = "::Concerns::#{name.titleize}::#{m}".constantize
      unless self.include?(__concern_module) 
        include __concern_module
      end
    end 
  end
end
