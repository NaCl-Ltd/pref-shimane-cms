# require 'susanoo/exports/page_creator'

module Susanoo
  class Export
    include Exports::Helpers::Logger
    include Exports::Helpers::Actionable
    include Exports::Helpers::JobHelper
    include Exports::Sync::Rsync
    include Exports::Helpers::PathHelper

    class_attribute :lock_file
    self.lock_file = File.join(Dir.tmpdir, 'export.lock')

    action_method(
        :all_page,
        :create_genre,
        :create_page,
        :cancel_page,
        :delete_page,
        :move_page,
        :delete_folder,
        :move_folder,
        :synchronize_folder,
        :create_htaccess,
        :create_htpasswd,
        :destroy_htaccess,
        :destroy_htpasswd,
        :remove_from_htpasswd,
        :create_all_section_page,
        :remove_attachment,
        :enable_remove_attachment,
      )

    #
    #=== Susanoo::Export処理
    #
    def run
      lock_file = File.open(self.lock_file, 'w')
      if lock_file.flock(File::LOCK_EX|File::LOCK_NB)
        while job = select_jobs.first
          begin
            args = [job.arg1, job.arg2].compact
            log("Start[#{job.id}]: '#{job.action}' With #{args.inspect}")
            self.send(job.action, *args)
            job.destroy
          rescue => e
            log("Error : #{e}, Backtrace : #{e.backtrace.inspect}")
            case e
            when ActiveRecord::RecordNotFound, Errno::ENOENT
              job.destroy
            else
              next_datetime = 10.minutes.since(Time.zone.now)
              need_rescue_job =
                if job.datetime
                  where_job_attrs = job.attributes.slice( *(Job.column_names - %w[id datetime]) )
                  !Job.where(where_job_attrs)
                      .where.not(id: job.id)
                      .datetime_le(next_datetime)
                      .exists?
                else
                  false
                end
              if need_rescue_job
                job.update(datetime: next_datetime)
              else
                job.destroy
              end
            end
          end
        end
      else
        log("他のプロセスが実行中です")
        exit 1
      end
    end

    #
    #=== 公開中ページと、ジャンルのページを作成?
    #
    def all_page
      add_all_create_genre_jobs
      add_all_create_page_jobs
    end

    #
    #=== create_genre Job
    #
    # Jobのアクションに'create_genre_job'が入っている時に、sendにより呼び出される
    def create_genre(genre_id)
      genre = Genre.find(genre_id)
      if path = genre.path
        page_creator = Exports::PageCreator.new(path)
        page_creator.make
      else
        log("Error : No Path #{genre.inspect}")
      end
    end

    #
    #=== create_page Job
    #
    # Jobのアクションに'create_page'が入っている時に、sendにより呼び出される
    def create_page(page_id)
      page = Page.find(page_id)
      page_creator = Exports::PageCreator.new(page.path)

      sn_before = SectionNews.exists?(page_id: page.id)

      maked = page_creator.make

      sn_after = SectionNews.exists?(page_id: page.id)
      sn_changed = sn_before ^ sn_after
      add_jobs_for_ancestors(page)    if maked
      add_jobs_for_section_news(page) if sn_changed
      add_jobs_for_top_news(page)     if page.visitor_content.try(:top_news?)
      disable_remove_attachment(page.path) unless maked
      page.clear_duplication_latest   if maked
    end

    #
    #=== cancel_page
    #
    # Jobのアクションに'cancel_page'が入っている時に、sendにより呼び出される
    def cancel_page(page_id)
      page = Page.find(page_id)
      page_creator = Exports::PageCreator.new(page.path)

      sn_before = SectionNews.exists?(page_id: page.id)

      page_creator.cancel

      sn_after = SectionNews.exists?(page_id: page.id)
      sn_changed = sn_before ^ sn_after

      destroy_remove_attachment(page.path)

      add_jobs_for_ancestors(page)
      add_jobs_for_section_news(page) if sn_changed
      add_jobs_for_top_news(page)     if page.visitor_content.try(:top_news?)
    end

    #
    #=== delete_page
    #
    # Jobのアクションに'delete_page'が入っている時に、sendにより呼び出される
    #
    # args; ページのID
    def delete_page(path)
      page_creator = Exports::PageCreator.new(path)
      page_creator.delete

      destroy_remove_attachment(path)
    end

    #
    #=== move_page
    #
    # Jobのアクションに'move_page'が入っている時に、sendにより呼び出される
    #
    # args: 移動先パス、元のパス
    def move_page(to_path, from_path)
      page_creator = Exports::PageCreator.new(from_path)
      page_creator.move(to_path)
      if genre = Genre.find_by(path: from_path)
        genre.add_genre_jobs_to_parent
      end
    end

    #
    #=== delete_folder
    #
    # Jobのアクションに'delete_folder'が入っている時に、sendにより呼び出される
    #
    # args: 削除するフォルダのパス
    def delete_folder(path)
      page_creator = Exports::PageCreator.new(path)
      page_creator.delete_dir
      destroy_remove_attachment(path)
    end

    #
    #=== move_folder
    #
    # Jobのアクションに'move_folder'が入っている時に、sendにより呼び出される
    #
    # args: 移動先パス, 元のパス
    def move_folder(to_path, from_path)
      page_creator = Exports::PageCreator.new(from_path)
      page_creator.move_dir(to_path)
      if genre = Genre.find_by(path: to_path)
        genres = genre.all_children
        parent_genre = genre.parent
        genres.unshift(parent_genre) if parent_genre && Genre.root.id != parent_genre.id
        genres.each{|g| Job.create(action: 'create_genre', arg1: g.id) if g.present?}
      end
      Job.create(action: 'synchronize_folder', arg1: from_path)
    end

    #
    #=== synchronize_folder
    #
    # Jobのアクションに'synchronize_folder'が入っている時に、sendにより呼び出される
    #
    # args: 同期させるフォルダのパス
    def synchronize_folder(path)
      page_creator = Exports::PageCreator.new(path)
      page_creator.sync_docroot(File.join(path, '/'))
    end

    #
    #=== create_htaccess
    #
    # Jobのアクションに'create_htaccess'が入っている時に、sendにより呼び出される
    #
    # args: ジャンルのID
    def create_htaccess(genre_id)
      apache = Exports::Creator::BasicAuth::Apache.new(genre_id)
      apache.make
    end

    #
    #=== create_htpasswd
    #
    # Jobのアクションに'create_htpasswd'が入っている時に、sendにより呼び出される
    #
    # args: ジャンルのID
    def create_htpasswd(genre_id)
      apache = Exports::Creator::BasicAuth::Apache.new(genre_id)
      apache.make_htpasswd
    end

    #
    #=== destroy_htaccess
    #
    # Jobのアクションに'destroy_htaccess'が入っている時に、sendにより呼び出される
    #
    # args: ジャンルのID
    def destroy_htaccess(genre_id)
      apache = Exports::Creator::BasicAuth::Apache.new(genre_id)
      apache.delete
    end

    #
    #=== destroy_htpasswd
    #
    # Jobのアクションに'destroy_htpasswd'が入っている時に、sendにより呼び出される
    #
    # args: ジャンルのID
    def destroy_htpasswd(genre_id)
      apache = Exports::Creator::BasicAuth::Apache.new(genre_id)
      apache.delete_htpasswd
    end

    #
    #=== remove_from_htpasswd
    #
    # Jobのアクションに'destroy_htpasswd'が入っている時に、sendにより呼び出される
    #
    # args: ジャンルのID、Basic認証のログインID
    def remove_from_htpasswd(genre_id, login)
      apache = Exports::Creator::BasicAuth::Apache.new(genre_id)
      apache.delete_htpasswd_with_login(login)
    end

    #
    #=== create_all_section_page
    #
    # Jobのアクションに'create_all_section_page'が入っている時に、sendにより呼び出される
    #
    # args: セクションのID
    def create_all_section_page(section_id)
      create_section_genre_pages_jobs(section_id)
    end

    #
    #=== remove_attachment
    #
    # Jobのアクションに'remove_attachment'が入っている時に、sendにより呼び出される
    # 添付ファイルを削除する
    #
    def remove_attachment(path)
      remove_file_path = export_path(path)
      if File.exist?(remove_file_path)
        log("Remove: #{remove_file_path}")
        FileUtils.rm(remove_file_path, {force: true})
        data_dir = remove_file_path.parent
        if data_dir.exist? && Dir.entries(data_dir).join == "..."
          FileUtils.rmdir(data_dir)
        end
      end
    end

    #
    #=== enable_remove_attachment
    #
    # remove_attachmentジョブを有効化する
    #
    def enable_remove_attachment(path)
      Job.eq_remove_attachment_with_path(path).update_all(datetime: nil)
    end

    private

      def select_jobs
        Job.queue_eq(:export).datetime_is_nil_or_le(Time.zone.now).where(action: self.action_methods.to_a)
      end
  end
end
