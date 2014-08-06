class PageRevision < ActiveRecord::Base
  include Concerns::PageRevision::Association
  include Concerns::PageRevision::Validation
  include Concerns::PageRevision::Method
end
