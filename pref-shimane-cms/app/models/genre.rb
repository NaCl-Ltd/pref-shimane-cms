class Genre < ActiveRecord::Base
  include Concerns::Genre::Association
  include Concerns::Genre::Validation
  include Concerns::Genre::Method
end
