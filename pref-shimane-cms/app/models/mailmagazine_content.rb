class MailmagazineContent < ActiveRecord::Base
  include Concerns::MailmagazineContent::Association
  include Concerns::MailmagazineContent::Validation
  include Concerns::MailmagazineContent::Method
end
