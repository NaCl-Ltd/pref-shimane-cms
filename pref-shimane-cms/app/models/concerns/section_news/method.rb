module Concerns::SectionNews::Method
  extend ActiveSupport::Concern

  included do
    default_scope { order('begin_date DESC') }

    scope :like_path, ->(path) {
      where('path LIKE ?', path)
    }

    scope :by_section, ->(section) {
      genre_ids = Genre.where(section_id: section).map(&:id)
      where(genre_id: genre_ids)
    }

    scope :top, -> {
      news = all
      except_top_path.each { |path| news.where!('path NOT LIKE ?', "#{path}%") }
      news
    }

    scope :top_with_max_date, ->(max_date) {
      news = top
      unless max_date.zero?
        date = Date.today - max_date
        news.where!('begin_date >= ? AND begin_date <= ?',
          date.beginning_of_day, Date.today.end_of_day)
      end
      news
    }

    scope :others, -> {
      news = all
      except_others_path.each { |path| news.where!('path NOT LIKE ?', "#{path}%") }
      news
    }

    scope :others_with_max_date, ->(max_date) {
      news = others
      unless max_date.zero?
        date = Date.today - max_date
        news.where!('begin_date >= ? AND begin_date <= ?',
          date.beginning_of_day, Date.today.end_of_day)
      end
      news
    }

    scope :under_path_with_max_date, ->(path, max_date) {
      news = where('path LIKE ?', "#{path}%")
      unless max_date.zero?
        date = Date.today - max_date
        news.where!('begin_date >= ? AND begin_date <= ?',
          date.beginning_of_day, Date.today.end_of_day)
      end
      news
    }

    #
    #=== pathが一致するものを削除する
    #
    scope :destroy_all_by_path, ->(path) {
      where('path = ?', path).destroy_all
    }
  end

  module ClassMethods
    def update_section_news(path)
      if page = Page.find_by_path(path)
        publish_content = page.publish_content
        section_news = SectionNews.find_or_initialize_by(page_id: page.id)
        if publish_content
          if publish_content.section_news == PageContent.section_news_status[:no]
            news = SectionNews.find_by_page_id(page.id)
            news.destroy if news
            return
          end
          section_news.update(
            page_id: page_id,
            begin_date: publish_content.begin_date,
            path: path,
            title: page.news_title,
            genre_id: page.genre_id,
          )
        else
          section_news.destroy
        end
      end
    end

    def create_news_pages(page)
      path = page.path
      case path
      when '/'
        Page.top_news
      when page.section_top_genre_path
        SectionNews.by_section(page.genre.section).includes(:page).map(&:page)
      when *Settings.news_pages.to_hash.values, *Settings.all_news_pages.to_hash.values
        SectionNews.includes(:page).like_path("#{path}%").references(:page).map(&:page)
      when Settings.top_news_page, Settings.top_all_news_page
        SectionNews.top.includes(:page).map(&:page)
      when Settings.other_news_page, Settings.other_all_news_page
        SectionNews.others.includes(:page).map(&:page)
      else
        SectionNews.like_path("#{page.genre.path}%").includes(:page).map(&:page)
      end
    end

    def multi_genre_news(args, max, max_date)
      news = []
      condition = ''
      add_con = ' or path like ?'
      target_data = []

      args.each do |arg|
        if arg =~ /^\/.*?\/$/ && Genre.find_by_path(arg)
          if condition.empty?
            condition = 'path like ?'
          else
            condition += add_con
          end
          target_data << arg + '%'
        end
      end

      if target_data
        if max_date.zero?
          news = SectionNews.find(:all, :conditions => [condition, *target_data],
                                  :order => 'begin_date desc')
        else
          date = Date.today - max_date
          start_date = Time.local(date.year, date.month, date.day, 0, 0, 0)
          end_date = Time.local(Date.today.year, Date.today.month,
                                Date.today.day,23, 59, 59)
          condition << 'and begin_date >= ?'
          condition << 'and begin_date <= ?'
          target_data << start_date
          target_data << end_date
          news = SectionNews.find(:all, :conditions => [condition,*target_data],
                                  :order => 'begin_date desc')
        end
      end

      return news[0..max] unless news.empty?
      return nil
    end

    #
    #=== その他の新着情報ページから除外するページパスを返す
    #
    def except_top_path
      if @_except_top_path.nil?
        if Settings.section_news && Settings.section_news.top && Settings.section_news.top.except
          @_except_top_path = Settings.section_news.top.except
        else
          @_except_top_path = []
        end
      end
      @_except_top_path
    end

    #
    #=== その他の新着情報ページから除外するページパスを返す
    #
    def except_others_path
      if @_except_others_path.nil?
        if Settings.section_news && Settings.section_news.other && Settings.section_news.other.except
          @_except_others_path = Settings.section_news.other.except
        else
          @_except_others_path = []
        end
      end
      @_except_others_path
    end
  end
end
