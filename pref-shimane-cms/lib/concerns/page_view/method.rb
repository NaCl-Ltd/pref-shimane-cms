# -*- coding: utf-8 -*-
module Concerns
  module PageView
    module Method
      extend ActiveSupport::Concern

      included do
        attr_accessor :dir, :file, :layout, :page, :genre, :publish_content, :edit, :engine_name, :mobile

        TOP_LAYOUT = :top_layout
        SECTION_TOP_LAYOUT = :section_top_layout
        GENRE_TOP_LAYOUT = :genre_top_layout
        NORMAL_LAYOUT = :normal_layout

        LAYOUT_TYPES = [
                        TOP_LAYOUT,
                        SECTION_TOP_LAYOUT,
                        GENRE_TOP_LAYOUT,
                        NORMAL_LAYOUT
                       ]

        LAYOUT_TYPES.each do |layout_name|
          define_method("#{layout_name}?") do
            layout_name == self.layout
          end
        end

        def initialize(path='', page_content: nil, engine_name: nil, mobile: false, edit: false)
          if path.blank? && page_content
            @publish_content = page_content
            @page = @publish_content.page
            @genre = @page.genre
            @layout = page_layout
            self.file = @page.name
          else
            path << '/index.html' unless path =~ /.*\.(html|html\.i|png)\z/
            @dir = File.dirname(path)
            @extension = (path =~ /.*\.html\.i\z/ ? '.html.i' : File.extname(path))
            self.file = File.basename(path, @extension)

            @genre = ::Genre.find_by_name(@dir)
            if @genre
              @page = @genre.pages.find_by(name: @file)
              @publish_content = @page.try(:visitor_content)
              unless @publish_content
                return {action: 'not_found', status: 404, layout: false} unless file == 'index'
              end
              @page = ::Page.index_page(@genre) if file == 'index' && !@publish_content
              @layout = page_layout
            end
          end
          @mobile = mobile
          @edit = edit
          if engine_name.present?
            @engine_name = engine_name
          end
        end

        #
        #=== 描画するViewの名称を返す
        #
        def rendering_view_name(mobile)
          @mobile = mobile
          if !self.publish_content
            if top?
              return mobile ? 'susanoo/visitors/mobiles/top' : 'top'
            elsif !self.layout || self.normal_layout?
              return {action: 'not_found', status: 404, layout: false}
            end
          end
          mobile ? 'susanoo/visitors/mobiles/content' : template
        end

        #
        #=== テンプレートパスを返す
        #
        def template
          custom_template = set_templates # Rails Engine拡張用
          return custom_template if custom_template

          if @mobile
            return "susanoo/visitors/mobiles/content"
          else
            if @engine_name
              return "#{@engine_name}/susanoo/visitors/show"
            else
              return top? ? "/susanoo/visitors/top/show" : "/susanoo/visitors/normal/show"
           end
          end
        end

        #
        #=== トップページかどうかを返す
        #
        def top?
          self.genre.try(:path) == '/' && self.file == 'index'
        end

        #
        #=== ページタイトルを返す
        #
        def title
          self.page.try(:title)
        end

        #
        #=== ページ名を返す
        #
        def name
          self.page.try(:name)
        end

        #
        #=== ページのURLパスを返す
        #
        def path
          self.genre.path
        end

        #
        #=== ページコンテンツを返す
        #
        def content
          self.publish_content.try(:content)
        end

        #
        #=== 携帯ページコンテンツを返す
        #
        def mobile_content
          if self.publish_content.try(:mobile).present?
            self.publish_content.mobile
          else
            # ジャンルで自動生成される index.html には　publish_content が nil であるため
            c = self.publish_content || @page.contents.first
            c.cleanup_mobile_content(c.content)
            c.mobile = c.edit_style_mobile_content
            c.normalize_mobile!
          end
        end

        #
        #=== 外部URLを含むページかどうかを返す
        #
        def external_uri_page?
          self.genre.try(:uri).present?
        end

        #
        #=== RSSが作成されるページかどうかを返す
        #
        def rss_create?
          !!self.page.try(:rss_create?)
        end

        #
        #=== RSSのパスを返す
        #
        def rss_path
          return nil unless n = self.name
          File.join(path.to_s, File.basename(n) + ".rdf")
        end

        private

        #
        #=== Rails Engineでset_templates拡張用メソッド
        #
        def method_missing(name)
          return false
        end

        def page_layout
          if self.page.try(:name) == 'index'
            if self.genre.path == '/'
              TOP_LAYOUT
            elsif !self.publish_content
              if ::Section.exists?(top_genre_id: self.genre.id)
                SECTION_TOP_LAYOUT
              else
                GENRE_TOP_LAYOUT
              end
            else
              NORMAL_LAYOUT
            end
          else
            NORMAL_LAYOUT
          end
        end
      end

      module ClassMethods
        #
        #=== not_found テンプレートを返す
        #
        def not_found_template
          {action: 'not_found', status: 404, layout: false}
        end
      end
    end
  end
end
