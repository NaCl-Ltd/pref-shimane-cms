# -*- coding: utf-8 -*-
module SiteDesign
  module Susanoo
    module PageView
      extend ActiveSupport::Concern


      #
      # === 使用するテンプレートのパスを返す
      #
      def set_templates
        if top?
          # トップページ
          return "/susanoo/visitors/top/show"
        else
          # その他のページ
          if @engine_name
            # エンジン専用のテンプレートを返す
            # event_calendar, blog_management, etc
            return "/susanoo/visitors/#{@engine_name}/show"
          elsif template_path = custom_page_path
            # 特定フォルダ以下の独自テンプレートを返す
            return template_path
          else
            return "/susanoo/visitors/normal/show"
          end
        end
      end

      private

      def custom_page_path
        if Settings.methods.include?(:site_design) &&
          Settings.site_design.methods.include?(:path)
          Settings.site_design.path.each do |name, site_design_path|
            if path =~ /^#{site_design_path}/
              case name
              when :custom
                return "/susanoo/visitors/custom/show"
              end
            end
          end
        end
        return false
      end
    end
  end
end
