class Help < ActiveRecord::Base
  include Concerns::Help::Association
  include Concerns::Help::Validation
  include Concerns::Help::Method
end
