module BlogManagement
  class Engine < ::Rails::Engine
    isolate_namespace BlogManagement

    # 階層化したlocalesの読み込み
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
    config.assets.precompile += [config.root.basename.join('*.js'), config.root.basename.join('*.css')]

    config.to_prepare do
      root = BlogManagement::Engine.root

      Dir.glob(root + "app/models/*.rb").each do |c|
        require_dependency(c)
      end

      Dir.glob(root + "app/controllers/susanoo/*.rb").each do |c|
        require_dependency(c)
      end

      # BlogManagementでの拡張のロード
      Dir.glob(root.join("lib/#{BlogManagement::Engine.engine_name}/ext/*.rb")).each do |c|
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
  end
end
