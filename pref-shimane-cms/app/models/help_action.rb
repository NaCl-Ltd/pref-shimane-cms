class HelpAction < ActiveRecord::Base
  include Concerns::HelpAction::Association
  include Concerns::HelpAction::Validation
  include Concerns::HelpAction::Method
end
