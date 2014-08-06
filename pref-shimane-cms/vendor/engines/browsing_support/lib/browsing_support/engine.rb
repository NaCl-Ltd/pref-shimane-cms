module BrowsingSupport
  class Engine < ::Rails::Engine
    isolate_namespace BrowsingSupport

    # 階層化したlocalesの読み込み
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
    config.assets.precompile += [config.root.basename.join('*.js'), config.root.basename.join('*.css')]

    config.to_prepare do
      root = BrowsingSupport::Engine.root
      engine_name = BrowsingSupport::Engine.engine_name

      Dir.glob(root.join("app/models/*.rb")).each do |c|
        require_dependency(c)
      end
      Dir.glob(root.join("app/controllers/**/*.rb")).each do |c|
        require_dependency(c)
      end

      # BrowsingSupport::Exports のロード
      require_dependency(root.join("lib/#{engine_name}/exports").to_s)

      # BrowsingSupportでの拡張のロード
      Dir.glob(root.join("lib/#{engine_name}/ext/*.rb")).each do |c|
        require_dependency(c)
      end

      # BrowsingSupport::ExportMp3 のロード
      require_dependency(root.join("lib/#{engine_name}/export_mp3").to_s)

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
