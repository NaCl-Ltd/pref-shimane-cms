class ActionMaster < ActiveRecord::Base
  include Concerns::ActionMaster::Association
  include Concerns::ActionMaster::Validation
  include Concerns::ActionMaster::Method
end
