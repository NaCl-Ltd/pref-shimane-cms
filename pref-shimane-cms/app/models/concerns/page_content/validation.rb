module Concerns::PageContent::Validation
  extend ActiveSupport::Concern

  included do
    validates :page_id, presence: true
    validates :admission, presence: true
    validates :latest, inclusion: { in: [true, false] }
  end
end
