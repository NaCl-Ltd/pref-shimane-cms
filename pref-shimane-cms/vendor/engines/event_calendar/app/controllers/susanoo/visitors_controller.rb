#
#= 閲覧管理コントローラ
#
class Susanoo::VisitorsController < ApplicationController
  include Concerns::Susanoo::VisitorsController

  before_action :set_event_page_view, only: %i(view preview)

  private

  def set_event_page_view
    if @page_view.page.try(:event?) || Genre.event_index_path?(@page_view.dir)
      @page_view.engine_name = EventCalendar.to_s.underscore

      unless @page_view.page.try(:event?)
        # 年、月、日のインデックスページは存在しない
        # そのた、イベントトップの下に仮想ジャンルを作成し、そのジャンルに紐付く仮想ページを作成する
        path = request.path
        path << '/index.html' unless path =~ /.*\.(html|html\.i|png)\z/
        if path =~ %r!(.*/)(\d\d\d\d)/(\d\d|\d)/(\d\d|\d)\.html(\z|\.i|\.r)\z!
          content = %Q!<%= plugin('event_calendar_day', '#{$1}', '#{$2}-#{$3}-#{$4}') %>!
          page_name = $4
          page_title = "#{$3}月#{$4}日 "
        elsif path =~ %r!(.*/)(\d\d\d\d)/(\d\d|\d)/(\z|index\.html(\z|\.i|\.r)\z)!
          content = %Q!<%= plugin('event_calendar_month', '#{$1}', '#{$2}-#{$3}') %>!
          page_name = 'index'
          page_title = "#{$3}月 "
        elsif path =~ %r!(.*/)(\d\d\d\d)/(\z|index\.html(\z|\.i|\.r)\z)!
          content = %Q!<%= plugin('event_calendar_year', '#{$1}', '#{$2}') %>!
          page_name = 'index'
          page_title = "#{$2}年 "
        else
          return false
        end

        event_top = Genre.find_by_name($1)
        page_title += event_top.title
        genre_path = path =~ /\/\Z/ ? path : File.dirname(path) + '/'
        genre = Genre.new(parent_id: event_top.id, path: genre_path, section:  event_top.section, title: event_top.title)

        @page_view.publish_content = PageContent.new(content: content, admission: PageContent.page_status[:publish])
        @page_view.genre = genre
        page = Page.new(name: page_name, title: page_title)
        page.genre = genre
        @page_view.page = page
      end
    end
  end
end
