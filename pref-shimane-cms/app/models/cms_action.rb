class CmsAction < ActiveRecord::Base
  include Concerns::CmsAction::Association
  include Concerns::CmsAction::Validation
  include Concerns::CmsAction::Method
end
