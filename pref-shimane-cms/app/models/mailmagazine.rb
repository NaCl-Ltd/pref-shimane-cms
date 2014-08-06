class Mailmagazine < ActiveRecord::Base
  include Concerns::Mailmagazine::Association
  include Concerns::Mailmagazine::Validation
  include Concerns::Mailmagazine::Method
end
