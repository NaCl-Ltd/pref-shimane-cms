require_relative 'server_sync_helper'

module Susanoo
  module Exports
    module Helpers

      #
      #= ページの中にあるカウンターの管理を行うモジュール
      #
      module CounterHelper
        REGEXP = /#{Regexp.quote(Settings.counter.url)}count.cgi\?id=\d+(?:&amp;start=(\d+))/
        DIR = Pathname.new(Rails.root).join(Settings.counter.data_dir)
        SYNC_DIR = Pathname.new(Settings.export.sync_counter_dir)
        SYNC_COUNTER_SERVERS = Array(Settings.export.sync_counter_servers || Settings.export.servers)
        FILE_PERMISSION = 0664

        #
        #=== includeされた時にフォルダを作成する
        #
        def self.included(klass)
          klass.send(:include, ServerSyncHelper)

          FileUtils.mkdir_p(DIR) unless FileTest.exist?(DIR)
        end

        #
        #=== カウンターを作成する
        #
        def create_counter(path, start_count=0)
          counter_file(path) do |exists, counter_path|
            # カウンターファイルが無い、またはファイルがあるが初期値が異なる場合
            if !exists || File.read(counter_path).chomp.to_i != start_count.to_i
              File.open(counter_path, 'w') {|f| f.print(start_count) }
              File.chmod(FILE_PERMISSION, counter_path)
              log("Create Counter: #{counter_path}")
              sync_counter(File.basename(counter_path))
            end
          end
        end

        #
        #=== カウンターを削除する
        #
        def remove_counter(path)
          counter_file(path) do |exists, counter_path|
            if exists
              File.delete(counter_path)
              log("Remove Counter: #{counter_path}")
              sync_counter(File.basename(counter_path))
            end
          end
        end

        #
        #=== カウンターがあれば作成して、無ければ削除する
        #
        def create_or_remove_counter(html, path)
          start_count = get_counter(html)
          counter_path = path.to_s
          start_count ? create_counter(counter_path, start_count) : remove_counter(counter_path)
        end

        #
        #=== HTMLに含まれるカウンターを返す
        #
        def get_counter(html)
          match = REGEXP.match(html)
          return match ? match[1] : nil
        end

        private

          #
          #=== カウンターファイルがあるかどうかを返す
          #
          # ブロックがあれば、結果とパスを引数にブロックを実行する
          def counter_file(path)
            if page = Page.find_by_path(path)
              counter_path = DIR.join(page.id.to_s)
              exists = File.exists?(counter_path)
              yield(exists, counter_path) if block_given?
              return exists
            else
              return false
            end
          end
      end
    end
  end
end

