require_relative '../backend/rsync'

module Susanoo
  module ServerSync
    module Syncers
      class Base
        include ActiveSupport::Configurable
        include ServerSync::Helpers::Loggable

        attr_accessor :server, :sync_files

        %i(src dest user priority).each do |attr|
          config_accessor attr
          define_method("#{attr}_with_proc") do
            val = self.send "#{attr}_without_proc"
            if val.respond_to?(:call)
              val.arity == 0 ? val.call : val.call(self)
            else
              val
            end
          end
          alias_method_chain attr, :proc
        end

        self.priority = 20  # Default

        def initialize(server, options = {})
          @server = server
          @sync_files = Array(options[:sync_files])
        end

        def run
          res = true
          log_prefix = "#{self.class.name}#run: Sync: Server '#{server}'"

          if sync_files.blank?
            logger.info("#{log_prefix}: Skip")
          else
            logger.info("#{log_prefix}: Begin")

            files = []
            sync_files.each do |sync_file|
              sync_file = sync_file
                .gsub(%r{(?<!\*)\*\Z}, '**')
                .gsub(%r{(?<!/)/+\Z}, '/**')
              Pathname.new(sync_file).descend{|v| files << v.to_s}
            end
            files.uniq!

            rsync = ServerSync::Backend::Rsync.new(src: src, dest: dest)
            rsync_options = []
            rsync_options << %Q{-aLz}
            # 15秒間隔で接続確認。3回失敗した場合は ssh を切断する。
            rsync_options << %Q{-e 'ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=3'}
            rsync_options << %Q{--delete-after}
            rsync_options << %Q{--include-from=-}
            rsync_options << %Q{--exclude=*}
            result = rsync.push({server: server, user: user, options: rsync_options}, stdin_data: files.join("\n"))

            if result.success?
              res = true
              logger.info("#{log_prefix}: Done")
            else
              res = false
              logger.error("#{log_prefix}: Failed (exitcode #{result.exitcode})")
              unless result.output.blank?
                result.output.each_line do |line|
                  logger.error(line.chop)
                end
              end
            end
          end

          res
        end
      end
    end
  end
end
