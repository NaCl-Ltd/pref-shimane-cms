#
#= 閲覧管理コントローラ
#
class Susanoo::VisitorsController < ApplicationController
  include Concerns::Susanoo::VisitorsController

  helper ::BlogManagement::CalendarHelper
  helper do
    def extract_headings(page, level = 1)
      if publish_content = page.try(:publish_content)
        headings = publish_content.content.scan(%r!<h#{level}[^>]*>(.+)</h#{level}>!).flatten
      end
      return headings || []
    end
  end

  before_action :set_blog_page_view, only: %i(view preview)

  private

  def set_blog_page_view
    if @page_view.page.try(:blog_page_or_index?)
      @page_view.engine_name = BlogManagement.to_s.underscore

      # 現在見ているページのジャンル
      # ブログトップ、年、月のジャンルのいづれか
      genre = @page_view.genre

      # ブログページの一覧表示用
      blog_page_ids = genre.blog_page_ids

      @blog_pages_with_content = []
      blog_page_count = 0
      Page.where(id: blog_page_ids).order("blog_date desc").each do |page|
        visitor_content = page.visitor_content
        if visitor_content
          @blog_pages_with_content << [page, visitor_content]
          blog_page_count += 1
        end
        # 月以外では、サイドメニューのページ一覧は最大30件
        break if blog_page_count >= 30 && genre.blog_folder_type != ::Genre.blog_folder_types[:month]
      end

      # インデックスページの場合でかつ、contentが空のときはプラグインを挿入する
      if !@page_view.page.blog_date? && @page_view.publish_content.try(:content).blank?
        @page_view.publish_content = PageContent.new(content: %Q!<%= plugin('blog_index', 5) %>!, admission: PageContent.page_status[:publish])
      end

      # カレンダーの日付リンク用
      @latest_blog_page = @blog_pages_with_content.first.try(:first)
      @month_blog_pages = []
      if @latest_blog_page
        @latest_blog_page.genre.pages.where.not(blog_date: nil).each do |page|
          @month_blog_pages[page.blog_date.day] = page if page.visitor_content
        end
      end

      # 次月移行で、公開中のページコンテンツが存在している直近の月フォルダを取得する
      @next_month_blog_genre = @latest_blog_page.genre.next_month if @latest_blog_page
      # 前月以前で、公開中のページコンテンツが存在している直近の月フォルダを取得する
      @prev_month_blog_genre = @latest_blog_page.genre.prev_month if @latest_blog_page

      # カレンダーの年、月
      if @latest_blog_page
        @calendar_year = @latest_blog_page.blog_date.year
        @calendar_month = @latest_blog_page.blog_date.month
      else
        # 該当するインデックスページ範囲に公開ページがないとき
        case genre.blog_folder_type
        when ::Genre.blog_folder_types[:top]
          @calendar_year = Date.today.year
          @calendar_month = Date.today.month
        when ::Genre.blog_folder_types[:year]
          @calendar_year = genre.name.to_i
          @calendar_month = Date.today.month
        when ::Genre.blog_folder_types[:month]
          @calendar_year = genre.parent.name.to_i
          @calendar_month = genre.name.to_i
        end
      end
    end
  end
end

