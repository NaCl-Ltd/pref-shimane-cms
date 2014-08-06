#
#= PageTemplate のバリデーションを管理するモジュール
#
module Concerns::PageTemplate::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true, uniqueness: true
    validates :content, presence: true
  end
end
