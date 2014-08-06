# -*- coding: utf-8 -*-
module Concerns::Susanoo::VisitorsController
  extend ActiveSupport::Concern

  included do
    layout false

    before_action :set_page_view, only: %i(view)
    before_action :set_mobile, only: %i(view)
    before_action :prepare_to_preview, only: %i(preview)
    skip_before_action :login_required, only: %i(attach_file)

    rescue_from self::PageNotFound do
      logger.info "#{self.class::PageNotFound} Received"
      render Susanoo::PageView.not_found_template
    end

    #
    #== 公開されているページを閲覧する機能
    #
    def view
      render @page_view.rendering_view_name(@mobile)
    end

    #
    #== ページのプレビュー機能
    #
    def preview
      render @page_view.rendering_view_name(@mobile)
    end

    #== 実際には存在していないページをプレビューする機能
    #
    def preview_virtual
      case params[:mode]
      when "template"
        page_template = ::PageTemplate.find(params[:template_id])
        page = Page.new(name: "preview", title: "プレビュー", genre: Genre.top_genre)
        page_content = PageContent.new(page: page, content: page_template.content)
        @page_view = ::Susanoo::PageView.new(page_content: page_content)
      end

      render @page_view.rendering_view_name(@mobile)
    end

    #
    #== ファイルを返却する
    #
    # * 窓口検索のJSONデータ返却
    # * QRコード作成(トップページのQRコードのみ)
    # * ページのファイルの返却
    #
    def attach_file
      if @attach_response && send_engine_attach_response
        return
      end

      path = request.path
      dir = File.dirname(path)
      file = File.basename(path)

      if path =~ /^\/images\//
        send_public_dot_file(:images, path, file)
        return

      elsif path =~ /^\/stylesheets\//
        send_public_dot_file(:stylesheets, path, file)
        return

      elsif path =~ /^\/javascripts\//
        send_public_dot_file(:javascripts, path, file)
        return

      elsif file == 'index.png'
        qr_code = RQRCode::QRCode.new("#{Settings.base_uri}index.html", size: 4, level: :h)
        send_data qr_code.to_img.to_s, type: 'image/png', disposition: 'inline'
      else
        if dir =~ /(.*)\.data/
          file = File.basename(path)
          page = Page.find_by_path("#{$1}.html")
          if page
            file_path = File.join(Settings.visitor_data_path, page.id.to_s, file)
            if File.exist?(file_path)
              send_file(file_path, stream: false, disposition: 'inline')
            else
              render nothing: true
            end
          else
            render nothing: true
          end
        else
          render nothing: true
        end
      end
    end

    private

      #== PaageViewをセットする
      #
      def set_page_view
        if @page_content
          @page_view ||= Susanoo::PageView.new(page_content: @page_content)
        else
          @page_view ||= Susanoo::PageView.new(request.path)
        end
      end

      #
      #== プレビュー用のインスタンス変数を設定する
      #
      def prepare_to_preview
        @page_content = PageContent.find(params[:id])
        @preview = true
        @mobile = (params[:mobile].present?) ? true : false

        # 一括ページ取り込みでのアクセシビリティチェック用
        if @page_content && params[:edit_style].present?
          @page_view = @page_content.edit_style_page_view(is_mobile: @mobile)
        else
          @page_view = Susanoo::PageView.new(page_content: @page_content)
        end
      end

      #
      #=== モバイルでのアクセスまたは、モバイル用のURLかを判定する
      #
      def set_mobile
        @mobile = (request.mobile? || request.path =~ %r!\.html\.i(?:#[^/]*)?(?:\?[^/]*)?\z!)
      end

      #
      #=== エンジンで作成した添付ファイルレスポンスを返す
      #
      def send_engine_attach_response
        case @attach_response[:type]
        when :file
          if File.exist?(@attach_response[:content])
            send_file(@attach_response[:content], disposition: 'inline')
            return true
          else
            render nothing: true
            return true
          end
        when :json
          render(json: @attach_response[:content])
          return true
        else
          return false
        end
      end

      #
      # public,ディレクトリ配下のファイルを返す
      #
      def send_public_dot_file(type, path, file)
        if Settings.visitor_attach_file_path && Settings.visitor_attach_file_path[type]
          Settings.visitor_attach_file_path[type].each do |conf|
            file = File.join(conf.to, file) if path =~ /#{conf.from}/
          end
        end

        file_path = Rails.root.join('public.', type.to_s, file).to_s

        if File.exist?(file_path)
          send_file(file_path, disposition: 'inline')
        else
          render nothing: true
        end
      end

  end

  # 現在の view を破棄し、404 Not Found を表示する例外クラス
  class PageNotFound < StandardError; end
end

