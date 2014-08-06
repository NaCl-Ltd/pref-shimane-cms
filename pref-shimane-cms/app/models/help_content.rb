class HelpContent < ActiveRecord::Base
  include Concerns::HelpContent::Association
  include Concerns::HelpContent::Validation
  include Concerns::HelpContent::Method
end
