class EventReferer < ActiveRecord::Base
  include Concerns::EventReferer::Association
  include Concerns::EventReferer::Validation
  include Concerns::EventReferer::Method
end
