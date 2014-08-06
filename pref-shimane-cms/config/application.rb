require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module PrefShimaneCms
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

    # 階層化したlocalesを読み込む
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    I18n.enforce_available_locales = false
    config.i18n.default_locale = :ja

    # エンジンの読み込み順を設定する
    if defined? SiteDesign::Engine
      # 各エンジンのテスト時にcustom_engineに依存してしまうので、testの際は読み込み順は変更しない
      config.railties_order = [SiteDesign::Engine,  :main_app,  :all] unless Rails.env.test?

      # デザイン系のlocalesは最後に読み込ませる
      config.i18n.load_path += SiteDesign::Engine.config.paths['config/locales'].existent
    end

    #
    # model, controller を Concerns で分割するために、カスタムジェネレータを指定する
    #
    config.generators do |g|
      g.orm                 :susanoo_active_record
      g.scaffold_controller :susanoo_controller
    end

    config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)

    # プリコンパイルする対象に、個別に読み込む　js, css を追加する
    # ckeditor.js を uglifierで圧縮すると、IE8でエラーが発生するため
    # precompile リストには入れない
    # ckeditor.js は プリコンパイルせずに gem からコピーする
    # @see lib/tasks/ckeditor.rake
    #
    config.assets.precompile += [
      'susanoo/*.js',
      'editor.js',
      'editor.iframe.js',
      'explore.js',
      'init.js',
      'info.js',
      "ckeditor/init.js",
      "ckeditor/config.toolbar.js",
      "ckeditor/config.allowed_content.js",
      "ckeditor/config.remove_empty_tags.js",
      "ckeditor/config.config.language_list.js",
      "bootstrap.ckeditor.modal.fix.js",
      'ckeditor/plugins/*.js',
      'ckeditor/filebrowser/javascripts/jquery.tmpl.min.js',
      'ckeditor/filebrowser/javascripts/fileuploader.js',
      'ckeditor/filebrowser/javascripts/application_modify.js',
      'susanoo/*.css',
      'editor.css',
      'editor.iframe.css',
      'editor.mobile.css',
      'explore.css',
      'treeview.css',
      'ckeditor/plugins/*.css',
    ]

    config.autoload_paths += %W(#{config.root}/lib)

    config.to_prepare do
      Dir.glob(Rails.root.join("app/models/*.rb")).each do |c|
        require_dependency(c)
      end
      Dir.glob(Rails.root.join("app/controllers/**/*.rb")).each do |c|
        require_dependency(c)
      end
    end

    #
    # RailsEngineで用意した設定ファイルを読み込む
    #
    initializer :load_rails_config_settings_in_engines, after: :load_rails_config_settings, group: :all do
      rails_config_const = Kernel.const_get(RailsConfig.const_name)
      Rails::Engine::Railties.engines.each do |e|
        engine_settings_yml = e.root.join("config", "settings.yml").to_s
        engine_env_settings_yml = e.root.join("config", "settings", "#{Rails.env}.yml").to_s
        root_engine_settings_yml = Rails.root.join("settings.#{e.engine_name}.yml").to_s

        rails_config_const.add_source!(engine_settings_yml) if File.exist?(engine_settings_yml)
        rails_config_const.add_source!(engine_env_settings_yml) if File.exist?(engine_env_settings_yml)
        rails_config_const.add_source!(root_engine_settings_yml) if File.exist?(root_engine_settings_yml)
      end
      rails_config_const.add_source!(Rails.root.join('config', 'accessibility.yml').to_s)
      rails_config_const.reload!
    end
  end
end

