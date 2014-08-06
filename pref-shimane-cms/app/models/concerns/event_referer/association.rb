#
#== EventReferer アソシエーション、属性を管理するモジュール
#
module Concerns::EventReferer::Association
  extend ActiveSupport::Concern

  included do

    #
    #=== プラグインのコード
    #
    @@plugin_code = {
      event_calendar_calendar: 0, event_calendar_pickup: 1, event_page_list: 2,
    }.with_indifferent_access

    #
    #=== プラグイン検索用正規表現オブジェクト
    #
    @@plugin_regexp = {
      event_calendar_calendar: Regexp.new("<%=\\s*plugin\\('event_calendar_calendar',\\s*'(.+?)',\\s*'(\\d|\\w)+'\\)\\s*%>"),
      event_calendar_pickup: Regexp.new("<%=\\s*plugin\\('event_calendar_pickup',\\s*'(.+?)',\\s*'\\d+'\\)\\s*%>"),
      event_page_list: Regexp.new("<%=\\s*plugin\\('event_page_list',\\s*'?\\d+'?\\)\\s*%>"),
    }.with_indifferent_access

    cattr_reader :plugin_code, :plugin_regexp
  end
end
