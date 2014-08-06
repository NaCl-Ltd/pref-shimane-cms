class EventReferer < ActiveRecord::Base
  include Concerns::EventReferer::Association
  include Concerns::EventReferer::Validation
  include Concerns::EventReferer::Method

  validates :path, uniqueness: {scope: [:plugin, :target_path]}

  # ページ編集時に、イベントカレンダー関連のプラグインがあるかチェックし、あれば登録する
  def self.regist(page_path)
    if Settings.event_calendar.remain_referer_paths.present?
      # contentにpluginが埋め込まれてないが、layoutにpluginがあるような特別なページは、自動でrefererを削除・更新しない
      return true if Settings.event_calendar.remain_referer_paths.include?(page_path)
    end

    EventReferer.delete_all(["path = ?", page_path])
    page = ::Page.find_by_path(page_path)
    if page.publish_content
      content = page.publish_content.content.to_s + page.publish_content.mobile.to_s
      plugins = ::EventReferer.plugin_code.keys
      plugins.each{ |plugin|
        content.scan(::EventReferer.plugin_regexp[plugin]){ |matched|
          event_referer = ::EventReferer.new
          event_referer.plugin = ::EventReferer.plugin_code[plugin]
          event_referer.path = page_path
          if $1
            event_referer.target_path = $1
          else
            event_referer.target_path = page_path
          end
          event_referer.save
        }
      }
    end
  end
end
