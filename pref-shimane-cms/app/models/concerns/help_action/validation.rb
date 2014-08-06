module Concerns::HelpAction::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :action_master_id, presence: true
  end
end
