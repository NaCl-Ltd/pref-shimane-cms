class HelpCategory < ActiveRecord::Base
  include Concerns::HelpCategory::Association
  include Concerns::HelpCategory::Validation
  include Concerns::HelpCategory::Method
end
