module Concerns::PageLock::Method
  extend ActiveSupport::Concern

  included do

    LOCK_TIME = 4.hour # 4時間

    #
    #=== 有効か？
    #
    def expired?
      return self.time + LOCK_TIME < Time.now
      return self.time < Time.now - LOCK_TIME
    end

  end

  module ClassMethods
  end
end
