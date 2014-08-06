module Susanoo
  module Exports
    module Creator

      #
      #= Exportの各ファイル作成クラスの基底クラス
      #
      class Base
        include Exports::Helpers::Logger
        include Exports::Helpers::PathHelper
        include Exports::Sync::Rsync
        include Helpers::ServerSyncHelper

        #
        #=== ActionDispatch::Integration::Sessionのインスタンスをセットする
        #
        def initialize
          @app = ActionDispatch::Integration::Session.new(PrefShimaneCms::Application)
        end

        private

          #
          #=== ファイルに書き込む
          #
          # ファイルまでのディレクトリが無ければ作成する
          # ファイルの内容が変更されていれば書き換える
          def write_file(dir, body, mode='w', options={})
            path = export_path(dir)
            dirname = File.dirname(path)
            FileUtils.mkdir_p(dirname) unless FileTest.exist?(dirname)
            old_content = File.exists?(path) ? File.read(path) : nil
            if old_content && body == old_content
              log("No Need To Create Page: #{path}")
              return false
            else
              log("Create #{File.extname(path).upcase}: #{path}")
              File.open(path, mode, options) {|f| f.print(body)}
              return body
            end
          end

          #
          #=== ファイルをディレクトリへコピーする
          #
          def copy_file(src, dest_dir, options={}, path_options={})
            path_options = {src_convert: true}.merge(path_options)
            srcs = Array(src)

            dir = export_path(dest_dir)
            srcs.map!{|s| path_options[:src_convert] ? export_path(s) : s}

            FileUtils.mkdir_p(dir) unless FileTest.exist?(dir)
            FileUtils.cp(srcs, dir, {preserve: true}.merge(options))
          end

          #
          #=== ファイルを削除する
          #
          def remove_file(path, options={})
            remove_file_path = export_path(path)
            if File.exist?(remove_file_path)
              log("Remove: #{remove_file_path}")
              FileUtils.rm(remove_file_path, {force: true}.merge(options))
            end
          end

          #
          #=== rm_rfコマンド実行する
          #
          def remove_rf(paths, options={})
            paths.map!{|path| export_path(path)}
            log("Remove: #{paths.join(',')}")
            FileUtils.rm_rf(paths, options)
          end

          #
          #=== 削除ファイル一覧へデータを書き込む
          #
          def add_remove_file_list(path)
            write_file(REMOVE_PAGE_LIST_PATH, "#{path}\n", 'a+')
            if File.extname(path) == '.html'
              write_file(REMOVE_PAGE_LIST_PATH, "#{path_with_type(path, :data)}/\n", 'a+')
            end
          end

          #
          #=== ファイルを移動させる
          #
          def mv_file(from_paths, to_path, options = {})
            to_export_path = export_path(to_path)
            from_paths.map!{|path| export_path(path)}
            FileUtils.mkdir_p(to_export_path) unless FileTest.exist?(to_export_path)
            begin
              FileUtils.mv(from_paths, to_export_path.to_s, {force: true}.merge(options))
            rescue ArgumentError
              # when same file exists
            end
          end

          def sync(src, dest, options={})
            log("#{src} => #{dest}")
            rsync(src, dest, options)
          end
      end
    end
  end
end
