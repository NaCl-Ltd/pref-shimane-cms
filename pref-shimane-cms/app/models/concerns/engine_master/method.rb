module Concerns::EngineMaster::Method
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods

    #=== Engineが有効かを返す。
    def enable?(engine_name)
      EngineMaster.where("name = ? AND enable = ?", engine_name, true).exists?
    end

    #=== エンジンクラスを全て返す。
    def engine_classes
      Dir.glob(Rails.root.join("vendor", "engines", "*")).map do |path|
        engine_klass = EngineMaster.constantize_engine(File.basename(path))
      end.compact
    end

    #=== Engineクラスを返す。
    def constantize_engine(engine_name)
      "#{engine_name.camelize}::Engine".constantize rescue nil
    end
  end

  #=== 有効・無効のラベルを返す。
  def enable_label
    I18n.t("activerecord.attributes.engine_master.enable_label.#{self.enable? ? "enable" : "disable" }")
  end
end
