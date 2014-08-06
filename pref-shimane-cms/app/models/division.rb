class Division < ActiveRecord::Base
  include Concerns::Division::Association
  include Concerns::Division::Validation
  include Concerns::Division::Method
end
