module Concerns::SiteComponent::Method
  extend ActiveSupport::Concern

  included do
  end

  module ClassMethods
    #=== find_by(name: name)をしてvalueを返す
    def [](name)
      self.find_by(name: name.to_s).value rescue nil
    end

    #=== 指定したnameのレコードをvalueで更新する
    def []=(name, value)
      self.find_by(name: name.to_s).update(value: value)
    end
  end
end
