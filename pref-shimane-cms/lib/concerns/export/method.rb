module Concerns
  module Export
    module Method
      extend ActiveSupport::Concern

      included do
      end

      module ClassMethods
      end

      def get_error_list(error_file)
        file = File.read(error_file)
        unless file.empty? || !REXML::Document.new(file).root
          REXML::XPath.match(REXML::Document.new(file), "//ul[@id='error_page_list']").first
        end
      end

      def add_to_sync_failed_page_ls(path)
        add_to_file(path, Settings.export.sync_failed_page_list)
        debug_log("add_to_sync_failed_page_ls: added.  page_url => #{path}")
      end

      def add_to_file(path, file_name)
        File.open(file_name, "a+") do |file|
          file.flock(File::LOCK_EX)
          file.puts(path)
        end
      end

      def rsync_to_remote(method_name, params={})
        if File.exist?(Settings.export.sync_enable_file_path)
          src = (params[:src_dir] || Settings.export.docroot) +
            (params[:src_path] || '')
          dest = (params[:dest_dir] || Settings.export.sync_dest_dir ) +
            (params[:dest_path] || '')
          if params[:servers]
            params[:servers].each do |server|
              if system("rsync #{params[:option]} #{src} #{Settings.export.user}@#{server}:#{dest}")
                debug_log("#{method_name} ----- #{src} ----- #{dest}")
              else
                debug_log("SYNC FAILED!! #{params[:src_path]}")
                url = params[:public_url]
                add_to_sync_failed_page_ls("#{Time.now.strftime('%FT%T')} #{method_name} #{url ? "URL: "+url : "path: "+params[:src_path]}")
              end
            end
          end
        end
      end

      def path_base(path)
        if /(.+)\.html\z/ =~ path
          return $1
        else
          "#{path}index"
        end
      end

      def path_html(path)
        "#{path_base(path)}.html"
      end

      def arg_to_path(arg)
        case arg
        when /\Ap:(\d+)\z/
          path = Page.find($1.to_i).path
        when /\Ag:(\d+)\z/
          path = Genre.find($1.to_i).path
        else
          path = arg
        end
        return path
      end
    end
  end
end
