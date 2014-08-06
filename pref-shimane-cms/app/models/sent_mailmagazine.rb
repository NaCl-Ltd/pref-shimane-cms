class SentMailmagazine < ActiveRecord::Base
  include Concerns::SentMailmagazine::Association
  include Concerns::SentMailmagazine::Validation
  include Concerns::SentMailmagazine::Method
end
