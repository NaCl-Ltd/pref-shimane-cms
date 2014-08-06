class SectionNews < ActiveRecord::Base
  include Concerns::SectionNews::Association
  include Concerns::SectionNews::Validation
  include Concerns::SectionNews::Method
end
