# -*- coding: utf-8 -*-
module Susanoo
  module Exports
    module Helpers

      #
      #= Exportの中でのJobの作成を行うヘルパー
      #
      module JobHelper
        @@news_pages = [
#          *Settings.news_pages.values,
#          *Settings.all_news_pages.values,
#          Settings.top_news_page,
          Settings.top_news_page
#          Settings.top_all_news_page,
#          Settings.other_news_page,
#          Settings.other_all_news_page
        ]

        #
        #=== 公開ページを持つ全てのページのJobを追加する
        #
        def add_all_create_page_jobs
          pages = Page.joins(:contents).merge(PageContent.eq_public).uniq
          pages.each do |page|
            add_create_page_jobs(page)
          end
        end

        #
        #=== 'create_page'のJobを追加する
        #
        def add_create_page_jobs(page)
          job = Job.find_by(action: 'create_page', arg1: page.id.to_s)
          if job && (job.datetime.nil? ||  job.datetime <= Time.now)
            return false
          else
            publish_content = page.publish_content
            if publish_content
              Job.create(action: 'create_page', arg1: page.id, datetime: publish_content.begin_date)
              if end_date = publish_content.end_date

                unless Job.exists?(["action = ? AND arg1 = ? AND datetime = ?", 'cancel_page', page.id.to_s, end_date])
                  Job.create(action: 'cancel_page', arg1: page.id, datetime: end_date)
                end
              end
            end
          end
        end

        #
        #=== トップジャンル以下のジャンルの、Jobを追加する
        #
        def add_all_create_genre_jobs
          Genre.top_genre.all_children.each do |genre|
            add_create_genre_jobs(genre)
          end
        end

        #
        #=== 'create_genre'のJobを追加する
        #
        def add_create_genre_jobs(genre)
          unless Job.exists?(action: 'create_genre', arg1: genre.id.to_s)
            Job.create(action: 'create_genre', arg1: genre.id)
          end
        end

        #
        #=== セクションのジャンルと、そのページを作り直すJobを追加する
        #
        def create_section_genre_pages_jobs(section_id)
          section = Section.find(section_id)
          section.genres.each do |genre|
            pages = genre.pages.joins(:contents).merge(PageContent.eq_published)
            pages.each{|page| add_create_page_jobs(page) }
            add_create_genre_jobs(genre)
          end
        end

        def disable_remove_attachment(path)
          Job.eq_enable_remove_attachment_with_path(path).destroy_all
        end

        def destroy_remove_attachment(path)
          Job.eq_remove_attachment_with_path(path).destroy_all
          disable_remove_attachment(path)
        end

        #
        #=== 所属新着に関連するページ、ジャンルをを更新するJobを追加する
        #
        def add_jobs_for_section_news(page, datetime = Time.zone.now)
          section_top_page_update(page, datetime)
          emergency_update(page, datetime)

          add_jobs_for_static_news_page(page, datetime) if !@@news_pages.include?(page.path)
        end

        #
        #=== トップ新着に関連するページ、ジャンルをを更新するJobを追加する
        #
        def add_jobs_for_top_news(page, datetime = Time.zone.now)
          Job.create_with(datetime: datetime)
             .find_or_create_by(action: 'create_genre', arg1: Genre.top_genre.id.to_s)
        end

        #
        #=== 親、祖父母、... のジャンルのindexページを更新するJobを追加する
        #
        def add_jobs_for_ancestors(page, datetime = Time.zone.now)
          page.genres.each do |genre|
            next if genre.path == '/'  # トップページは top_news で

            Job.create_with(datetime: datetime)
               .find_or_create_by(action: 'create_genre', arg1: genre.id.to_s)
          end
        end

        private

          #
          #=== 設定ファイルに記述してある静的ニュースファイルを作成する
          #
          # 旧: add_jobs_for_news
          def add_jobs_for_static_news_page(page, datetime)
            genre_name = page.genre.name
            paths = [Settings.top_news_page, Settings.top_all_news_page]
            if n_name = settings_news_pages[genre_name]
              paths.concat([n_name, settings_all_news_pages[genre_name]])
            else
              paths.concat([Settings.other_news_page, Settings.other_all_news_page])
            end
            paths.compact.each do |path|
              if page = Page.find_by_path(path)
                Job.create_with(datetime: datetime)
                   .find_or_create_by(action: 'create_page', arg1: page.id.to_s)
              end
            end
          end

          #
          #=== ページのセクションTOPページを作成しなおすJobを追加する
          #
          def section_top_page_update(page, datetime)
            if genre = Genre.find_by(id: page.section.try(:top_genre_id))
              Job.create_with(datetime: datetime)
                 .find_or_create_by(action: 'create_genre', arg1: genre.id.to_s)
            end
          end

          #
          #=== Pageが緊急情報の場合に、トップページを作成しなおすJobを追加する
          #
          def emergency_update(page, datetime)
            if page.path =~ /^\/emergency\/.*$/
              Job.create_with(datetime: datetime)
                 .find_or_create_by(action: 'create_genre', arg1: Genre.top_genre.id.to_s)
            end
          end

          #
          #=== 設定ファイルに定義した新着情報ページの設定を返す
          #
          def settings_news_pages
            @settings_news_pages ||= Settings.news_pages ? Settings.news_pages.to_h.with_indifferent_access : {}
          end

          #
          #=== 設定ファイルに定義した過去の新着情報ページの設定を返す
          #
          def settings_all_news_pages
            @settings_all_news_pages ||= Settings.all_news_pages ? Settings.all_news_pages.to_h.with_indifferent_access : {}
          end
      end
    end
  end
end
