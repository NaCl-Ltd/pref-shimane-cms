class Section < ActiveRecord::Base
  include Concerns::Section::Association
  include Concerns::Section::Validation
  include Concerns::Section::Method
end
