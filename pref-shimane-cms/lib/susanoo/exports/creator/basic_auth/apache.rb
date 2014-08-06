require_relative File.expand_path('../../base', __FILE__)
require_relative File.expand_path('../../../helpers/server_sync_helper', __FILE__)

module Susanoo
  module Exports
    module Creator
      module BasicAuth
        TEMPLATE_DIR = Rails.root.join('lib/susanoo/exports/creator/basic_auth/template')

        #
        #= Apacheのベーシック認証設定ファイルを作成・削除する
        #
        class Apache < Creator::Base
          include Exports::Helpers::ServerSyncHelper

          @@template_path = {
            htaccess: TEMPLATE_DIR.join('apache', 'htaccess.erb'),
            htpasswd: TEMPLATE_DIR.join('apache', 'htpasswd.erb')
          }
          cattr_accessor :template_path

          SYNC_HTPASSWD_DIR = Settings.export.public_htpasswd_dir

          #
          #=== 初期化　
          #
          def initialize(genre_id)
            @genre = Genre.find(genre_id)
            @htaccess_path = File.join(@genre.path, ".htaccess")
            @htpasswd_path = File.join(Settings.export.local_htpasswd_dir, @genre.id.to_s)
          end

          #
          #=== .htaccess、htpasswd作成処理を呼び出す
          #
          def make
            make_htaccess
            make_htpasswd
          end

          #
          #=== .htaccess、htpasswd削除処理を呼び出す
          #
          def delete
            delete_htaccess
            delete_htpasswd
          end

          #
          #=== .htpasswdファイルを作成する
          #
          # templateフォルダにある、ERBテンプレートから作成する
          def make_htpasswd
            web_monitors = @genre.web_monitors.eq_registered
            template = ERB.new(File.read(@@template_path[:htpasswd]), nil, '-')
            htaccess_content = template.result(binding)
            _write_file(@htpasswd_path, htaccess_content)

            sync_htpasswd_file
          end

          #
          #=== .htpasswdを削除する
          #
          def delete_htpasswd
            _remove_file(@htpasswd_path)
            sync_htpasswd_file
          end

          #
          #=== 引数で渡されたloginに一致する行を削除する
          #
          def delete_htpasswd_with_login(login)
            new_content = []
            if File.exists?(@htpasswd_path)
              File.open(@htpasswd_path) do |f|
                f.each_with_object(new_content) do |line, content|
                  content << line unless line =~ /^#{login}:/
                end
              end
              _write_file(@htpasswd_path, new_content.join)

              sync_htpasswd_file
            end
          end

          private

            #
            #=== .htaccessファイルを作成する
            #
            # ./templateフォルダにある、ERBテンプレートから作成する
            def make_htaccess
              template = ERB.new(File.read(@@template_path[:htaccess]), nil, '-')
              htaccess_content = template.result(binding)
              write_file(@htaccess_path, htaccess_content)

              sync_htaccess_file
            end

            #
            #=== .htaccessファイルを削除する
            #
            def delete_htaccess
              remove_file(@htaccess_path)

              sync_htaccess_file
            end

            #
            #=== .htaccessファイルを同期する
            #
            def sync_htaccess_file
              sync_docroot(@htaccess_path)
            end

            #
            #=== ベーシック認証パスワードファイルを同期する
            #
            def sync_htpasswd_file
              sync_htpasswd(File.basename(@htpasswd_path))
            end

            #
            #=== ファイルに書き込む
            #
            # ファイルまでのディレクトリが無ければ作成する
            # ファイルの内容が変更されていれば書き換える
            def _write_file(path, body, mode='w')
              dirname = File.dirname(path)
              FileUtils.mkdir_p(dirname) unless FileTest.exist?(dirname)
              old_content = File.exists?(path) ? File.read(path) : nil
              if old_content && body == old_content
                log("No Need To Create Page: #{path}")
                return false
              else
                log("Create #{File.extname(path).upcase}: #{path}")
                File.open(path, mode) {|f| f.print(body)}
                return body
              end
            end

            #
            #=== ファイルを削除する
            #
            def _remove_file(path, options={})
              remove_file_path = path
              if File.exist?(remove_file_path)
                log("Remove: #{remove_file_path}")
                FileUtils.rm(remove_file_path, {force: true}.merge(options))
              end
            end
        end
      end
    end
  end
end

