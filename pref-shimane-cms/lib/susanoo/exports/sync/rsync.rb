require_relative '../helpers/path_helper'

module Susanoo
  module Exports
    module Sync
      module Rsync
        USER = Settings.export.user
        DEFAULT_OPTIONS = '-aLz --delete --timeout=5'
        SYNC_ENABLE_FILE_PATH = Rails.root.join('do_sync')

        def self.included(klass)
          klass.send(:include, Susanoo::Exports::Helpers::PathHelper)
        end

        #
        #=== 設定されているサーバと同期する
        #
        # 同期先のサーバとのssh(鍵認証方式)の設定が終了している前提
        def rsync(src, dest, options={})
          if FileTest.exists?(SYNC_ENABLE_FILE_PATH)
            servers = options[:servers] || Settings.export.servers
            servers.each do |server|
              src_path  = options[:no_change_src]  ? src  : create_src_path(options[:src_dir], src.to_s)
              dest_path = options[:no_change_dest] ? dest : create_dest_path(options[:dest_dir], dest.to_s)
              run_command("rsync #{options[:option] || DEFAULT_OPTIONS} #{src_path} #{USER}@#{server}:#{dest_path}")
              log("Error : Rsync filed (remote server: #{server}, exitstatus: #{$?.exitstatus})") if respond_to?(:log) && $?.exitstatus != 0
            end
          end
        end

        private

          #
          #=== ソースパスを生成する
          #
          def create_src_path(src_dir, src_path)
            # src_pathがエクスポート元のフルパスである場合は、そのまま返却する
            return src_path if export_path?(Pathname.new(src_path))

            dir = Pathname.new("#{src_dir || Settings.export.docroot}")
            dir.to_s + src_path
          end

          #
          #=== 同期先のパスを作成
          #
          def create_dest_path(dest_dir, dest_path)
            dir = Pathname.new("#{dest_dir || Settings.export.sync_dest_dir}")
            dir.to_s + dest_path
          end

          #
          #=== rsycコマンドを実行する
          #
          def run_command(cmd)
            system("#{cmd} 2>&1")
          end
      end
    end
  end
end

