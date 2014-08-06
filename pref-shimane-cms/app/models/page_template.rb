class PageTemplate < ActiveRecord::Base
  include Concerns::PageTemplate::Association
  include Concerns::PageTemplate::Validation
  include Concerns::PageTemplate::Method
end
