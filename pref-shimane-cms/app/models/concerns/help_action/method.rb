module Concerns::HelpAction::Method
  extend ActiveSupport::Concern

  included do
    START_INDEX = 1
  end

  module ClassMethods
    #=== ヘルプチェック
    def help_check(action, controller)
      controller_name = controller
      controller_name = 'admin' unless controller
      cms_action = ::CmsAction.find_by(controller_name: controller_name, action_name: action)
      if cms_action
        master = cms_action.action_master
        if master
          action = ::HelpAction.find_by(action_master_id: master.id)
          return action.help_category_id if action
        end
      end
      return nil
    end
  end
end
