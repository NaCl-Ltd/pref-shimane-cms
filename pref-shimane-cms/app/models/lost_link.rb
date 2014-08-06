class LostLink < ActiveRecord::Base
  include Concerns::LostLink::Association
  include Concerns::LostLink::Validation
  include Concerns::LostLink::Method
end
