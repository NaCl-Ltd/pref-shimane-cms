module ConsultManagement
  class Engine < ::Rails::Engine
    isolate_namespace ConsultManagement

    # 階層化したlocalesの読み込み
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    config.assets.precompile += [config.root.basename.join('*.js'), config.root.basename.join('*.css')]

    config.to_prepare do
      root = ConsultManagement::Engine.root

      Dir.glob(root + "app/controllers/susanoo/*.rb").each do |c|
        require_dependency(c)
      end

      # FactoryGirl のセットアップ
      if defined? FactoryGirl
        # 本 Engine 以下の factory のパスを追加する
        FactoryGirl.definition_file_paths += [
            root.join('factories'),
            root.join('test', 'factories'),
            root.join('spec', 'factories')
          ]
      end
    end

    config.after_initialize do
      require Rails.root.join('lib', 'susanoo', 'exports', 'creator', 'base')
      require "consult_management/susanoo/export"
      ::Susanoo::Export.send(:include, ::ConsultManagement::Susanoo::Export)
    end
  end
end
