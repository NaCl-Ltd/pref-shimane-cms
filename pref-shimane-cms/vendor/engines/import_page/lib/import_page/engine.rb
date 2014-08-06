module ImportPage
  class Engine < ::Rails::Engine
    isolate_namespace ImportPage

    # 階層化したlocalesの読み込み
    config.paths['config/locales'].glob = "**/*.{rb,yml}"

    config.generators do |g|
      g.test_framework :rspec, :view_specs => false
    end
    config.assets.precompile += [config.root.basename.join('*.js'), config.root.basename.join('*.css')]

    config.to_prepare do
      root = Engine.root
      engine_name = Engine.engine_name

      Dir.glob(root.join("app/models/**/*.rb")).each do |c|
        require_dependency(c)
      end
      Dir.glob(root.join("app/controllers/**/*.rb")).each do |c|
        require_dependency(c)
      end
    end
  end
end
