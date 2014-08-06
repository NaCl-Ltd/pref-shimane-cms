require_relative 'base'

module Susanoo
  module ServerSync
    module Syncers
      class CounterSyncer < self::Base
        self.src  = lambda { File.join(Rails.root.join(Settings.counter.data_dir), '/') }
        self.dest = lambda { File.join(Settings.export.sync_counter_dir, '/') }
        self.user = lambda { Settings.export.user }
        self.priority = 10
      end
    end
  end
end
