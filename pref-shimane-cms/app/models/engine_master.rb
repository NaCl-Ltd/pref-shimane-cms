class EngineMaster < ActiveRecord::Base
  include Concerns::EngineMaster::Association
  include Concerns::EngineMaster::Validation
  include Concerns::EngineMaster::Method
end
