require 'fileutils'
require 'rexml/document'

require_relative 'exports/helpers/path_helper'
require_relative 'voice_synthesis'

module BrowsingSupport
  class ExportMp3
    include Susanoo::Exports::Helpers::Actionable
    include Exports::Helpers::PathHelper

    class_attribute :logger, :lock_file
    self.logger = Logger.new(Rails.root.join('log/export_mp3.log'))
    self.logger.level = Rails.logger.level
    self.lock_file = Pathname.new(Dir.tmpdir).join('export_mp3.lock')

    class_attribute :retry_interval
    self.retry_interval = 10.minutes  # 再試行間隔

    action_method :create_mp3

    def self.run
      exporter = new
      
      lock! do
        while job = select_jobs.first do
          begin
            exporter.run(job)
          rescue
            exporter.logger.error $!
            exporter.logger.error "backtrace: #{$!.backtrace.inspect}"

            if job.datetime
              new_job = job.dup
              new_job.datetime = Time.zone.now + retry_interval
              new_job.save
            end
          ensure
            job.destroy
          end
        end
      end
    end

    def self.lock!
      File.open(lock_file, 'w') do |f|
        unless f.flock(File::LOCK_EX|File::LOCK_NB)
          logger.error("他のプロセスが実行中です")
          return
        end
     
        begin
          yield
        ensure
          FileUtils.rm_f f.path
        end
      end
    end

    def self.select_jobs
      # 全ての queue の create_mp3 を処理する
      Job.unscope(where: :queue).datetime_is_nil_or_le(Time.zone.now).where(action: self.action_methods.to_a)
    end

    def run(job)
      args = [job.arg1, job.arg2].compact
      log("Job[#{job.id}]: Start: '#{job.action}' With #{args.inspect}")
      public_send(job.action, *args)
      log("Job[#{job.id}]: End: '#{job.action}' With #{args.inspect}")
    end

    def create_mp3(arg, tmp_id = nil)
      path = arg_to_path(arg)
      html_path = export_path(path)
      tmp_dir = if tmp_id.blank?
          Dir.mktmpdir(nil, Rails.root.join('tmp'))
        else
          Rails.root.join('tmp', tmp_id).to_s
        end
      tmp_id = File.basename(tmp_dir) if tmp_id.blank?

      # 公開停止などでファイルが削除された場合は、
      # tempディレクトリを削除し、処理を終了する
      unless File.exist?(html_path)
        FileUtils.rm_rf(tmp_dir)
        return
      end

      voice_synthesis.html2m3u(
        html_path.to_s,
        File.join(Settings.public_uri, path),
        dest_dir: tmp_dir
      )
      Job.create(action: 'move_mp3',
                 arg1: arg.to_s,
                 arg2: tmp_id.to_s,
                 datetime: Time.now)
    rescue => e
      FileUtils.rm_rf(tmp_dir)
      raise e
    end

    private

    def voice_synthesis
      @voice_synthesis ||= begin
          BrowsingSupport::VoiceSynthesis.new(Settings.browsing_support.voice_synthesis.to_hash).tap do |vs|
            vs.logger = self.logger
          end
        end
    end

    def debug_log(msg)
      logger.debug(msg)
    end
    def error_log(msg)
      logger.error(msg)
    end
    def fatal_log(msg)
      logger.fatal(msg)
    end
    def info_log(msg)
      logger.info(msg)
    end
    def unknown_log(msg)
      logger.unknown(msg)
    end
    def warn_log(msg)
      logger.warn(msg)
    end
    alias_method :log, :info_log
  end
end
