module Susanoo
  module Exports
    module Helpers
      module Logger
        def log(message)
          logger.info("[Susanoo Export] #{message}")
        end

        # Export や Creator などで利用されているため、
        # Export側で logger を変更しても、Creator などへは反映されない。
        # Creator 側へも反映させるためには、
        # Exports::Helpers::Logger.logger= メソッドを利用し、変更する。
        def logger
          @logger ||= Susanoo::Exports::Helpers::Logger.logger
        end
        def self.logger
          @logger ||= ::Logger.new(Rails.root.join('log/export.log'))
        end

        def self.logger=(logger)
          @logger = logger
        end
      end
    end
  end
end
