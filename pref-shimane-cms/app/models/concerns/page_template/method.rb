module Concerns::PageTemplate::Method
  extend ActiveSupport::Concern

  included do
    before_validation :set_content, :if => lambda { |r| r.new_record? }
    before_update :normalize_content


    private

    def set_content
      self.content ||= "<h1>#{name}</h1>"
    end

    # NOTE: PageContent#save_with_normalizationから必要な処理を持ってきてますので、コンテンツの変換処理が変わったときは注意
    def normalize_content
      if self.content_changed?
        _content = self.content.split("\n").inject("") {|s, l| s += l.strip}
        page_content = PageContent.new(content: _content)
        _content = page_content.send(:normalize_content, _content)
        _content = page_content.send(:plugin_tag_to_erb, _content)

        self.content = _content
      end
    end
  end

  module ClassMethods
  end
end
