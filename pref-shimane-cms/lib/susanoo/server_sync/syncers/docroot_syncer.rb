require_relative 'base'

module Susanoo
  module ServerSync
    module Syncers
      class DocrootSyncer < self::Base
        self.src  = lambda { File.join(Settings.export.docroot, '/') }
        self.dest = lambda { File.join(Settings.export.sync_dest_dir, '/') }
        self.user = lambda { Settings.export.user }
      end
    end
  end
end
