module Concerns::Division::Method
  extend ActiveSupport::Concern

  included do
    scope :enables, -> {where("enable = ?", true)}
  end

  module ClassMethods
  end

  # === 組織別情報に表示する・しないを表示
  def enable_label
    I18n.t("activerecord.attributes.division.enable_label.#{self.enable? ? "enable" : "disable" }")
  end
end
