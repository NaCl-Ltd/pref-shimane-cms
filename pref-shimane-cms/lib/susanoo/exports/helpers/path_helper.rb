module Susanoo
  module Exports
    module Helpers

      #
      #= Exportで使用するパスまわりのメソッドを持つヘルパーモジュール
      #
      module PathHelper
        EXPORT_PATH = Pathname.new(Settings.export.docroot)
        REMOVE_PAGE_LIST_PATH = Pathname.new(Settings.export.remove_page_list_dir).join(Time.now.strftime('%Y%m%d'))
        TOP_PAGE_PATH = '/index.html'

        @@file_type = {
          html: 'html', rubi: 'html.r', mobile: 'html.i',
          m3u: 'm3u', qr: 'png', data: 'data', rss: 'rdf'
        }.with_indifferent_access


        #
        #=== 引数渡されたパスを、エクスポートするパスに変更して返す
        #
        def export_path(path)
          if export_path?(path)
            path
          else
            EXPORT_PATH.join(*path.to_s.split(/\//))
          end
        end

        #
        #=== エクスポートのパスかどうかを返す
        #
        def export_path?(path)
          %r|\A#{EXPORT_PATH.to_s}/.*| =~ path.to_s
        end

        #
        #=== 基本となるパスを作成する
        #
        # /example/index.html => '/example/index'
        # /example/ => '/example/index'
        def base_path(path)
          /(.+)\.html\z/ =~ path.to_s ? $1 : File.join(path, "index")
        end

        #
        #=== タイプによって、拡張子を変更したパスを返す
        #
        def path_with_type(path, type=:html)
          Pathname.new("#{base_path(path.to_s)}.#{@@file_type[type]}")
        end

        #
        #=== パスからトップページかを返却する
        #
        def top_page?(path)
          path.to_s == TOP_PAGE_PATH
        end
      end
    end
  end
end

