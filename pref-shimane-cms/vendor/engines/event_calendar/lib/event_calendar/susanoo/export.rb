require "event_calendar/susanoo/exports/xml_creator"

module EventCalendar
  module Susanoo
    module Export

      extend ActiveSupport::Concern

      included do
        action_method *%i(
            create_event_page
            cancel_event_page
            update_event_page_title
          )
      end

      #
      #=== xmlの作成・更新・rsyncとインデックスページのrsyncを行う。イベントツールを使用しているページに対して、create_pageするJobを作成する。
      #
      # Jobのアクションに'create_event_page'が入っている時に、sendにより呼び出される
      def create_event_page(page_id)
        # xmlのの作成・更新処理
        page = Page.find(page_id)
        if page.visitor_content
          xml_creator = ::EventCalendar::Susanoo::Exports::XmlCreator.new(page.event_top.path)
          xml_creator.delete_elements(page)
          xml_creator.add_elements(page)
          xml_creator.make

          # インデックスページの作成・sync処理
          index_page_paths(page).each do |path|
            page_creator = ::Susanoo::Exports::PageCreator.new(path)
            page_creator.make
          end

          # イベントツールを使用しているページに対するcreate_pageJOBの作成
          create_page_job_for_event_referers(page)
        end
      end

      #
      #=== xmlの更新・rsyncとインデックスページのrsyncを行う。イベントツールを使用しているページに対して、create_pageするJobを作成する。
      #
      # Jobのアクションに'cancel_event_page'が入っている時に、sendにより呼び出される
      def cancel_event_page(page_id)
        # xmlのの更新処理
        page = Page.find(page_id)
        xml_creator = ::EventCalendar::Susanoo::Exports::XmlCreator.new(page.event_top.path)
        xml_creator.delete_elements(page)
        xml_creator.make

        doc = Nokogiri::XML(xml_creator.body)

        # インデックスページの更新、削除・sync処理
        index_page_paths(page).each do |path|
          page_creator = ::Susanoo::Exports::PageCreator.new(path)
          if %r(/(\d+)/(\d)+/(\d+)\.html\Z) =~ path
            date = Date.new($1.to_i, $2.to_i, $3.to_i) rescue nil
            if date && doc.xpath("//events//date[text()='#{date.year}-#{date.month}-#{date.day}']").any?
              page_creator.make    # ページを更新
            else
              page_creator.delete  # ページは削除
            end
          else
            page_creator.make    # インデックスページは更新
          end
        end

        # イベントツールを使用しているページに対するcreate_pageJOBの作成
        create_page_job_for_event_referers(page)
      rescue ActiveRecord::RecordNotFound => e
        log("Error : #{e}")
      end

      #
      #=== インデックスページのrsyncを行う
      #
      # Jobのアクションに'update_event_page_title'が入っている時に、sendにより呼び出される
      def update_event_page_title(genre_id)
        genre = Genre.find(genre_id)

        # ジャンル以下の全イベントページに係る、インデックス系ページのパスを取得する
        paths = genre.descendants_pages.map do |page|
          index_page_paths(page)
        end.flatten.uniq

        # インデックスページの作成・sync処理
        paths.each do |path|
          event_page_creator = ::EventCalendar::Susanoo::Exports::EventPageIndexCreator.new(path)
          event_page_creator.make
        end
      end

      private

      def index_page_paths(page)
        base_path = page.event_top.path
        year_paths = []

        range =
          if page.begin_event_date && page.end_event_date
            (page.begin_event_date .. page.end_event_date)
          else
            []
          end
        # 年、月、日とページを作らないとrsyncでerrorが出る
        paths = range.map do |date|
          year_path = File.join(base_path, date.year.to_s + "/")
          year_paths << year_path
          month_path = File.join(base_path, date.year.to_s, date.month.to_s + "/")
          day_path = File.join(base_path, date.year.to_s, date.month.to_s, date.day.to_s + ".html")
          [year_path, month_path, day_path]
        end.flatten.uniq.sort

        # 年フォルダは、作成された月フォルダに影響を受けるので、後から再作成する
        paths.concat(year_paths.uniq)
      end

      def create_page_job_for_event_referers(page)
        target_paths = [page.event_top, page.event_category].compact.map(&:path)
        referers = ::EventReferer.where(target_path: target_paths).select(:path)
        update_paths = referers.map{ |r| r.path }.uniq
        update_paths.each do |path|
          page = Page.find_by_path(path)
          unless page.nil?
            Job.create(action: Job::CREATE_PAGE, arg1: page.id.to_s)
          end
        end
      end
    end
  end
end
