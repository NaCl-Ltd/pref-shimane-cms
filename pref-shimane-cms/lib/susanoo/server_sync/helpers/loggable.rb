module Susanoo
  module ServerSync
    module Helpers
      module Loggable
        extend ActiveSupport::Concern

        included do
          class_attribute :_logger

          def logger
            self._logger || ServerSync.logger
          end

          def logger=(logger)
            self._logger = logger
          end
        end

        module ClassMethods
          def logger
            self._logger || ServerSync.logger
          end

          def logger=(logger)
            self._logger = logger
          end
        end
      end
    end
  end
end
