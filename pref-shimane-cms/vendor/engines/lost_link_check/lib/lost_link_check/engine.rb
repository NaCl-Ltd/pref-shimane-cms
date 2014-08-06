require 'active_support/core_ext/numeric/bytes' if Rails.env == "test"

module LostLinkCheck
  class Engine < ::Rails::Engine
    isolate_namespace LostLinkCheck

    # 階層化したlocalesの読み込み
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    config.assets.precompile += [config.root.basename.join('*.js'), config.root.basename.join('*.css')]

    config.to_prepare do
      root = LostLinkCheck::Engine.root

      Dir.glob(root + "app/models/*.rb").each do |c|
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
