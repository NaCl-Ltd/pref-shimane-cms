require 'active_support/core_ext/numeric/bytes' if Rails.env == "test"

module SectionInfoConfigure
  class Engine < ::Rails::Engine
    isolate_namespace SectionInfoConfigure

    # 階層化したlocalesの読み込み
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
    config.assets.precompile += [config.root.basename.join('*.js'), config.root.basename.join('*.css')]

    config.to_prepare do
      root = SectionInfoConfigure::Engine.root

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
