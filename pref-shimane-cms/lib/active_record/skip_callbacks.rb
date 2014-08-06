#
#=== コールバックをスキップするためのモジュール
#
module ActiveRecord::SkipCallbacks
  extend ActiveSupport::Concern

  included do
  
    #
    #=== コールバックをスキップするかどうか判定する
    # デフォルトの状態ではコールバックをスキップしない
    #
    def skip_callbacks?
      @skip_callbacks.nil? ? false : @skip_callbacks
    end

    #
    #=== コールバックをスキップする
    #    
    def skip_callbacks
      @skip_callbacks = true
    end

    #
    #=== コールバックのスキップを解除する
    #    
    def cancel_skip_callbacks
      @skip_callbacks = false
    end
  end
end
