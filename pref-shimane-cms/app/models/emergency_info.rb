class EmergencyInfo < ActiveRecord::Base
  include Concerns::EmergencyInfo::Association
  include Concerns::EmergencyInfo::Validation
  include Concerns::EmergencyInfo::Method
end
