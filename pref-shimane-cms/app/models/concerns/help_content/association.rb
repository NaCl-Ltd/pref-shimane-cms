module Concerns::HelpContent::Association
  extend ActiveSupport::Concern

  included do
    has_many :helps, dependent: :destroy

    # ファイルアップロード用の一時キー
    attr_accessor :temp_key
  end
end
