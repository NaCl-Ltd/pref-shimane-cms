class PageLock < ActiveRecord::Base
  include Concerns::PageLock::Association
  include Concerns::PageLock::Validation
  include Concerns::PageLock::Method
end
