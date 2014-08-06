module Susanoo
  module ServerSync
    NULL_LOGGER = Logger.new(IO::NULL)

    def logger
      @logger || NULL_LOGGER
    end

    def logger=(logger)
      @logger = logger || NULL_LOGGER
    end

    def sync_enabled?
      FileTest.exist?(Settings.export.sync_enable_file_path)
    end
    module_function :logger, :logger=, :sync_enabled?
  end
end

require_relative 'server_sync/worker'
