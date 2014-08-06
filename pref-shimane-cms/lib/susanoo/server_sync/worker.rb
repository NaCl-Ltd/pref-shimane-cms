require_relative 'helpers/loggable'
require_relative '../exports/helpers/actionable'

module Susanoo
  module ServerSync
    class Worker
      include ServerSync::Helpers::Loggable
      include ::Susanoo::Exports::Helpers::Actionable

      class_attribute :retry_interval
      self.retry_interval = 10.minutes  # 再試行間隔

      action_method :sync_docroot, :sync_counter, :sync_htpasswd

      def self.run
        orig_logger = Susanoo::ServerSync.logger
        Susanoo::ServerSync.logger = Logger.new(Rails.root.join("log/server_sync.#{Rails.env}.log"))
        Susanoo::ServerSync.logger.level = Logger::Severity::INFO
        new.run
      ensure
        Susanoo::ServerSync.logger = orig_logger if orig_logger
      end

      def run
        ordered_actions = %i(sync_htpasswd sync_counter sync_docroot)

        find_jobs_in_batches(batch_size: 100) do |jobs|
          exit unless Susanoo::ServerSync.sync_enabled?  # raise SystemExit

          run_at = Time.zone.now
          ::Job.where(id: jobs.map(&:id)).update_all(datetime: run_at)
          grouped_jobs = jobs.group_by(&:action).with_indifferent_access

          ordered_actions.each do |action|
            _jobs = grouped_jobs[action]
            next if _jobs.blank?

            _job_ids = _jobs.map(&:id)
            begin
              public_send(action, _jobs)
              ::Job.delete_all(id: _job_ids, datetime: run_at)
            rescue
              logger.error("#{$!}, Backtrace: #{$!.backtrace.inspect}")

              ::Job.where(id: _job_ids, datetime: run_at).update_all(datetime: Time.zone.now + retry_interval)
            end
          end
        end

      rescue SystemExit
      end

      def sync_docroot(jobs)
        logger.info("#{self.class.name}#sync_docroot: Begin")

        servers = Array(Settings.export.servers)
        syncers = servers.map {|server| Syncers::DocrootSyncer.new(server) }
        fire(jobs, syncers)

        logger.info("#{self.class.name}#sync_docroot: Done")
      end

      def sync_counter(jobs)
        logger.info("#{self.class.name}#sync_counter: Begin")

        servers = Array(Settings.export.sync_counter_servers)
        syncers = servers.map {|server| Syncers::CounterSyncer.new(server) }
        fire(jobs, syncers)

        logger.info("#{self.class.name}#sync_counter: Done")
      end

      def sync_htpasswd(jobs)
        logger.info("#{self.class.name}#sync_htpasswd: Begin")

        servers = Array(Settings.export.servers)
        syncers = servers.map {|server| Syncers::HtpasswdSyncer.new(server) }
        fire(jobs, syncers)

        logger.info("#{self.class.name}#sync_htpasswd: Done")
      end

      private

        def select_jobs
          quoted_arg2 = ::Job.connection.quote_table_name('jobs.arg2')
          ::Job.unscope(where: :qeueu)
            .datetime_is_nil_or_le(Time.zone.now)
            .where(action: self.action_methods.to_a)
            .order("#{quoted_arg2} NULLS FIRST")
            .order(:id)
        end

        def find_jobs_in_batches(options = {})
          options.assert_valid_keys(:batch_size)

          batch_size = options[:batch_size] || 1000

          jobs = select_jobs.limit(batch_size).to_a
          while jobs.any?
            yield jobs

            jobs = select_jobs.limit(batch_size).to_a
          end
        end

        def fire(jobs, syncers)
          jobs = Array(jobs)
          syncers = Array(syncers).index_by(&:server)
          servers = syncers.keys

          logger.debug("#{self.class.name}#fire: Perform jobs:")
          jobs.each do |job|
            logger.debug("  #{job.inspect}")

            srvs = job.arg2
            srvs = servers if srvs.blank?
            Array(srvs).each do |server|
              if syncers[server]
                syncers[server].sync_files << job.arg1
              else
                logger.warn("Job[#{job.id}]: Server '#{server}' Not Found.")
              end
            end
          end

          syncers.values.sort_by(&:priority).inject(true) do |result, syncer|
            res = syncer.run
            unless res
              will_run_at = Time.zone.now + retry_interval
              new_jobs = jobs.map(&:dup)
              new_jobs.each do |j|
                j.assign_attributes(datetime: will_run_at, arg2: syncer.server)
              end
              # 100 件毎に bulk insert
              new_jobs.each_slice(100) do |_new_jobs|
                ::Job.import _new_jobs
              end
            end
            result & res
          end
        end
    end
  end
end
