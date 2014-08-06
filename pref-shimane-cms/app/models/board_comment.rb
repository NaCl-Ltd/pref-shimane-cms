class BoardComment < ActiveRecord::Base
  include Concerns::BoardComment::Association
  include Concerns::BoardComment::Validation
  include Concerns::BoardComment::Method
end
