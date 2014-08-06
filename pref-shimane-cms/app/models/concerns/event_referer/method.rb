#
#== EventReferer のクラスメソッド、インスタンスメソッドを管理するモジュール
#
module Concerns::EventReferer::Method
  extend ActiveSupport::Concern

  included do
    EVENT_CALENDAR = 0
    EVENT_PICKUP = 1
  end

  module ClassMethods

    #
    #=== プラグインの有無を返す
    #
    def has_plugin?(target_str)
      target_str.gsub!(/<!--.*?-->/, '')
      plugin_regexp.each { |plugin, regexp|
        return true if target_str =~ regexp
      }
      return false
    end
  end
end
