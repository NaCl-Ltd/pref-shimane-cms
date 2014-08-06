module Concerns::HelpAction::Association
  extend ActiveSupport::Concern

  included do
    belongs_to :help_category
    belongs_to :action_master
  end
end
