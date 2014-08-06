module Concerns::PageLink::Method
  extend ActiveSupport::Concern

  included do
    def replace_link_regexp!(pattern, replacement)
      self.link = link.sub(pattern, replacement)
      save!
    end
  end

  module ClassMethods
  end
end
