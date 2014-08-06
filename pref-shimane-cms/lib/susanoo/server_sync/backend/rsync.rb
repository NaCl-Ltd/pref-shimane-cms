# -*- coding: utf-8 -*-
require 'open3'

module Susanoo
  module ServerSync
    module Backend
      class Rsync
        cattr_accessor :default_options, instance_writer: false, instance_reader: false
        attr_accessor :src, :dest, :server, :user, :options

        #
        #== 指定したサーバに送信する
        #
        def self.push(options = {}, stdin = {})
          src     = options[:src]
          dest    = options[:dest]
          user    = options[:user]
          server  = options[:server]
          options = Array(options[:options] || self.default_options)

          destination = ""
          destination << "#{user}@" unless user.blank?
          destination << "#{server}:" unless server.blank?
          destination << "#{dest}"

          output, exitcode = rsync(*options, src, destination, stdin)
          Result.new(output, exitcode)
        end

        def initialize(options = {})
          @src     = options[:src]
          @dest    = options[:dest]
          @user    = options[:user]
          @server  = options[:server]
          @options = options[:options] || self.class.default_options.try(:dup)
        end

        #
        #== 指定したサーバに送信する
        #
        def push(options = {}, stdin = {})
          options[:src]    ||= self.src
          options[:dest]   ||= self.dest
          options[:user]   ||= self.user
          options[:server] ||= self.server
          options[:options] = Array(options[:options] || self.options)

          self.class.push(options, stdin)
        end

        class Result
          attr_reader :raw, :exitcode

          def initialize(raw, exitcode)
            @raw = raw
            @exitcode = exitcode
          end

          def success?
            @exitcode == 0
          end

          def output
            @raw
          end
        end

        private

          def self.rsync(*args)
            options = args.extract_options!

            cmd = "rsync #{args.join(' ')}"
            stdin_data = options[:stdin_data]
            stdin_data = stdin_data.read if stdin_data.respond_to?(:read)

            Susanoo::ServerSync.logger.debug("#{self.class.name}.rsync: Command: #{cmd}")

            stdin, stdout_and_stderr, wait_thr = Open3.popen2e(cmd)

            stdin.binmode if options[:binmode] == true
            stdin.write(stdin_data) if options.key?(:stdin_data)
            stdin.close

            [stdout_and_stderr.read, wait_thr.value.exitstatus]
          ensure
            # Close stdin for pipe
            stdin.close if stdin && !stdin.closed?
            # Kill command process
            Process.kill(:INT, wait_thr.pid) rescue nil if wait_thr && wait_thr.alive?
            # This prevents the process from becoming defunct
            stdout_and_stderr.close if stdout_and_stderr && !stdout_and_stderr.closed?
          end
      end
    end
  end
end
