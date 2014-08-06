class PageLink < ActiveRecord::Base
  include Concerns::PageLink::Association
  include Concerns::PageLink::Validation
  include Concerns::PageLink::Method
end
