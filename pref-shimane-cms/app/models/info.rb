class Info < ActiveRecord::Base
  include Concerns::Info::Association
  include Concerns::Info::Validation
  include Concerns::Info::Method
end
