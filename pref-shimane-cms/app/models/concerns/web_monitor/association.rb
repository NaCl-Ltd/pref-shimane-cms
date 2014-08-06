module Concerns::WebMonitor::Association
  extend ActiveSupport::Concern

  included do

    belongs_to :genre

    #
    #=== アクセス制限の状態
    #
    @@status = {
      edited: 0, registered: 1
    }.with_indifferent_access

    cattr_reader :status
  end
end
