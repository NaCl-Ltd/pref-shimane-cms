class News < ActiveRecord::Base
  include Concerns::News::Association
  include Concerns::News::Validation
  include Concerns::News::Method
end
