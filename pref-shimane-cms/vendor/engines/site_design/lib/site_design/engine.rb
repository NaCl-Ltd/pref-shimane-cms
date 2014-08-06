module SiteDesign
  class Engine < ::Rails::Engine
    isolate_namespace SiteDesign

    initializer "site_design_precompile_hook" do |app|
      app.config.assets.precompile += %w[
        editor.iframe.css
      ]
    end

    config.to_prepare do
      require_dependency "site_design/susanoo/page_view"
      ::Susanoo::PageView.send(:include, ::SiteDesign::Susanoo::PageView)
    end
  end
end
