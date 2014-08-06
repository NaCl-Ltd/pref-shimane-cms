module AdvertisementManagement
  class Engine < ::Rails::Engine
    isolate_namespace AdvertisementManagement

    # 階層化したlocalesの読み込み
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end

    config.assets.precompile += [config.root.basename.join('*.js'), config.root.basename.join('*.css')]

    config.to_prepare do
      root = AdvertisementManagement::Engine.root

      Dir.glob(root + "app/controllers/susanoo/*.rb").each do |c|
        require_dependency(c)
      end

      Dir.glob(root + "app/helpers/susanoo/*.rb").each do |c|
        require_dependency(c)
      end

      Dir.glob(root + "app/mailers/*.rb").each do |c|
        require_dependency(c)
      end

      require_dependency "advertisement_management/susanoo/export"
      ::Susanoo::Export.send(:include, ::AdvertisementManagement::Susanoo::Export)

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
  end
end
