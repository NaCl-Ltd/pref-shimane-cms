class WebMonitor < ActiveRecord::Base
  include Concerns::WebMonitor::Association
  include Concerns::WebMonitor::Validation
  include Concerns::WebMonitor::Method
end
