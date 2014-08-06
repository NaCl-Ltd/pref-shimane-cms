# -*- coding: utf-8 -*-
module Susanoo
  module Exports

    #
    #= 公開ページの作成・削除を行うクラス
    #
    class PageCreator < Creator::Base
      include Helpers::CounterHelper
      include Helpers::ServerSyncHelper

      def initialize(path='/')
        @path = Pathname.new(path)
        @path = @path.join('index.html') if path.last == '/'
        super()
      end

      #
      #=== 各ファイルを作成する
      #
      #
      # args: アクセスするパス
      #
      def make
        if create_normal_page
          create_mobile_page
          extname = File.extname(@path)

          src = "#{@path.dirname + @path.basename(extname)}.*"
          sync_docroot(src)

          return true
        else
          return false
        end
      end

      #
      #== ページを移動させる
      #
      def move(to_path)
        mv_file(Dir.glob("#{export_path(base_path(@path))}.*"), to_path)
        add_remove_file_list(@path)

        path_base = base_path(@path)
        src = "#{@path.dirname + path_base}.*"
        sync_docroot(src)

        dest = File.join(to_path, "#{File.basename(path_base)}.*")
        sync_docroot(dest)
      end

      #
      #=== ページの公開停止を行う
      # ページを削除して、削除ファイル一覧へ書き込む
      #
      def cancel
        self.delete
        add_remove_file_list(@path)
      end

      #
      #=== ページの削除を行う
      #
      def delete
        news = SectionNews.find_by_path(@path.to_s)
        news.destroy if news
        remove_rf(Dir.glob("#{export_path(base_path(@path))}.*"))

        path_base = base_path(@path)
        sync_docroot("#{path_base}.*")
      end

      #
      #=== ディレクトリの削除を行う
      #
      def delete_dir
        dir_path = @path.dirname
        remove_rf([dir_path])
        add_remove_file_list(dir_path)
        SectionNews.destroy_all_by_path(dir_path.to_s)

        sync_docroot(File.join(dir_path, '/'))
      end

      #
      #=== ディレクトリの移動を行う
      #
      def move_dir(to_path)
        dir_path = @path.dirname
        remove_rf([dir_path])
        add_remove_file_list(dir_path)

        # 公開側でのフォルダ削除を移動先のフォルダ・ページ作成が
        # 終了したタイミングで行わせるため、コメントアウト
        # 同期処理については本メソッドの呼び出し元で行うこと
        # sync_docroot(File.join(dir_path, '/'))

        # 不完全な状態でのRsyncの為コメントアウト
        # 移動先のフォルダ・ページ作成は各々のジョブで行う
        # dirname = File.dirname(to_path)
        # to_sync_dir = (dirname.last == '/' ? dirname : "#{dirname}/")
        # sync(to_sync_dir, to_sync_dir)
      end

      private

        #
        #=== ノーマルページを作成して、ファイルに書き込む
        #
        def create_normal_page
          @app.get(@path.to_s)

          # HTTPステータスコードが 200 でない場合は、ログを出力し、スキップする
          unless @app.response.ok?
            log("Error : Cannot Create Page #{@path} : Status Code #{@app.status} Received")
            return false
          end

          if html = write_file(@path, @app.body)
            @page = Page.find_by_path(@path.to_s)
            if @page && @page.visitor_content
              news = SectionNews.find_by_page_id(@page.id)
              news.destroy if news
              unless @page.visitor_content.section_news.zero?
                news = SectionNews.new(page_id: @page.id, begin_date: @page.visitor_content.date,
                                       path: @path.to_s, title: @page.news_title, genre_id: @page.genre.id)
                news.save!
              end
            end
            create_or_remove_counter(html, @path)
            copy_attach_file
            rss_create if @page  # ページがある時のみ作成する
            qr_create

            return true
          else
            return false
          end
        end

        #
        #=== モバイル用のページを作成して、ファイルに書き込む
        #
        def create_mobile_page
          mobile_path = path_with_type(@path, :mobile)
          @app.get(mobile_path.to_s)

          # HTTPステータスコードが 200 でない場合は、ログを出力し、スキップする
          unless @app.response.ok?
            log("Error : Cannot Create Page #{mobile_path} : Status Code #{@app.status} Received")
            return false
          end

          # CP932に存在しない「〜」(U+301C) への対応
          body = Susanoo::Filter.convert(@app.body, 'utf-8', 'cp932')
          write_file(mobile_path, body, 'w', encoding: "cp932")
        end

        #
        #=== ページのファイルをコピーする
        #
        def copy_attach_file
          # indexページの自動生成の場合、@pageはnilとなるため
          if @page
            src_dir = File.join(Settings.visitor_data_path, @page.id.to_s)
            if File.directory?(src_dir)
              data_path = path_with_type(@path, :data)
              src_dir = File.join(src_dir, '*')
              copy_file(Dir.glob(src_dir), data_path, {}, src_convert: false)
            end
          end
        end

        #
        #=== 渡されたページのパスのページがRSSを作成する必要があれば、RSSを作成する
        #
        def rss_create
          if @page
            if @page.publish_content.try(:content) =~ PageContent::RSS_REGEXP
              rss_creator = RssCreator.new(@page, SectionNews.create_news_pages(@page))
              rss_creator.make
            end
          end
        end

        #
        #=== 渡されたパスから、QRコードを作成する
        #
        def qr_create
          if top_page?(@path)
            qr_code = QrCodeCreator.new(@path)
            qr_code.make
          else
            return true
          end
        end
    end

  end
end
