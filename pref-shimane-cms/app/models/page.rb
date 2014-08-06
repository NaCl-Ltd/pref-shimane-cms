class Page < ActiveRecord::Base
  include Concerns::Page::Association
  include Concerns::Page::Validation
  include Concerns::Page::Method
end
