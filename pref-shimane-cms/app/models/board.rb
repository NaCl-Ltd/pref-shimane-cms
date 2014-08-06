class Board < ActiveRecord::Base
  include Concerns::Board::Association
  include Concerns::Board::Validation
  include Concerns::Board::Method
end
