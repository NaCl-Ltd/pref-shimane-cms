require_relative 'base'

module Susanoo
  module ServerSync
    module Syncers
      class HtpasswdSyncer < self::Base
        self.src  = lambda { File.join(Settings.export.local_htpasswd_dir, '/') }
        self.dest = lambda { File.join(Settings.export.public_htpasswd_dir, '/') }
        self.user = lambda { Settings.export.user }
        self.priority = 10
      end
    end
  end
end
