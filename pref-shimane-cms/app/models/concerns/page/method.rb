# -*- coding: utf-8 -*-
#
#= Page のクラスメソッド、インスタンスメソッドを管理するモジュール
#
module Concerns::Page::Method
  extend ActiveSupport::Concern

  included do
    after_destroy :clean_jobs
    after_destroy :remove_attachment_dir

    # ページ検索用
    scope :search, ->(genre, opt={}, additional={}) {
      order_column = additional[:order_column]
      user = additional[:user]

      s = PageContent.page_status
      g = Genre.arel_table
      p = Page.arel_table
      c = PageContent.arel_table

      sc = PageContent.all
      sg = Genre.all

      r = Page.all

      if opt[:recursive] != '1'
        r.where!(p[:genre_id].eq(genre.id))
      else
        sg.where!(g[:path].matches("#{genre.path}%"))
      end

      if user && !user.admin?
        sg.where!(g[:section_id].eq(user.section_id))
      end

      r.joins!(:genre).merge!(sg)

      # キーワードでname,titleの部分一致を行う
      if opt[:keyword].present?
        key = "%#{opt[:keyword]}%"
        r.where!(p[:title].matches(key).or(p[:name].matches(key)))
      end

      # 公開処理済みのPageContentに対する条件を指定した場合
      # 最新コンテンツフラグがtrueのPageContentを対象とする
      if (opt[:admission].present? && [s[:waiting],s[:publish],s[:finished],s[:cancel]].include?(opt[:admission])) ||
        opt[:start_at].present? || opt[:end_at].present? ||
        (order_column == "page_contents.last_modified")
        sc.where!(c[:latest].eq(true))
      end

      # 公開待ち、公開中、公開期限切れを指定した場合
      # PageContentのbegin_date(公開開始日)とend_date(公開終了日)から公開状態を判定する
      if opt[:admission].present?
        now = Time.zone.now
        case opt[:admission]
        when s[:editing], s[:request], s[:reject], s[:cancel]
          sc.where!(c[:admission].eq(opt[:admission]))
        when s[:waiting]
          sc.where!(c[:admission].eq(s[:publish]))
          sc.where!(c[:begin_date].not_eq(nil).and(c[:begin_date].gt(now)))
        when s[:publish]
          sc.where!(c[:admission].eq(s[:publish]))
          sc.where!(c[:begin_date].eq(nil).or(c[:begin_date].lteq(now)))
          sc.where!(c[:end_date].eq(nil).or(c[:end_date].gt(now)))
        when s[:finished]
          sc.where!(c[:admission].eq(s[:publish]))
          sc.where!(c[:end_date].not_eq(nil).and(c[:end_date].lteq(now)))
        end
      else
        sc = sc.where!(c[:admission].not_eq(nil))
      end

      sc.where!(c[:last_modified].gteq(opt[:start_at].beginning_of_day)) if opt[:start_at].present?
      sc.where!(c[:last_modified].lteq(opt[:end_at].end_of_day)) if opt[:end_at].present?

      if opt[:include_copy] != "1"
        r.where!(p[:original_id].eq(nil))
        r.includes!(:contents)
      else
        r.joins!("LEFT OUTER JOIN page_contents ON (page_contents.page_id = pages.id OR page_contents.page_id = pages.original_id)")
      end

      r.merge(sc).
        references([:genres, :contents]).
        uniq
    }

    #
    #===ページコンテンツを返す
    # コピーしたページの場合、コピー元のページの持つコンテンツを返す
    #
    def original_contents(force_reload = false)
      if original.blank?
        contents(force_reload)
      else
        original.contents(force_reload)
      end
    end

    #
    #=== 最新の公開コンテンツを返す
    #
    def latest_content(force_reload = false)
      original_contents(force_reload).eq_public.first
    end

    #
    #=== Visitorの公開ページで利用するコンテンツを返す
    # 最新の公開コンテンツの状態が公開中の場合、コンテンツを返すが、公開停止などの場合はnilを返す
    #
    def visitor_content
      status = PageContent.page_status[:publish]
      str = original_contents.eq_public.order("id DESC")
      # 公開したコンテンツが一つも無い場合
      return nil if str.empty?
      # HEADが公開中の場合
      if str.first.admission == status && str.first.publish_started? && str.first.publish_not_finished?
        return str.first
      end
      # HEADが公開待ちで、その一つ前のコンテンツが公開中の場合
      if str.first.admission == status && (!str.first.begin_date || (str.first.begin_date && str.first.begin_date > Time.zone.now))
        if str.size > 1 && str[1].admission == status
          return str[1]
        end
      end

      return nil
    end

    #
    #=== 公開中のコンテンツを返す
    # 最新の公開コンテンツの状態が公開中の場合、コンテンツを返す
    #
    def publish_content
      content = original_contents.eq_public.eq_public_start.first
      if content && content.publish? && content.publish_not_finished?
        content
      else
        nil
      end
    end

    #
    #=== 公開中のコンテンツか最新のものを返す。
    #
    def publish_or_latest_content
      publish_content || latest_content
    end

    #
    #=== 公開済みのコンテンツを返す
    # 状態が公開中または公開停止のコンテンツから公開開始日が現在日以降のコンテンツを返す
    #
    def published_content
      original_contents.eq_published.first
    end

    #
    #=== 未公開コンテンツを返す
    # 公開待ちのコンテンツは含まない
    #
    def private_content
      original_contents.eq_private.first
    end

    #
    #=== 未公開コンテンツを返す。無い場合は新規インスタンスを返す。
    #
    def private_content_or_new
      content = self.private_content
      return content if content
      if pub = self.publish_or_latest_content
        content = pub.dup
        content.last_modified = Time.now
      else
        content = PageContent.new
      end
      content.admission = PageContent.page_status[:editing]
      content.page = self
      content
    end

    #
    #=== 未公開コンテンツを返す
    # 公開待ちのコンテンツを含む
    #
    def unpublished_content
      private_content || waiting_content
    end

    #
    #=== 公開待ちのコンテンツを返す
    # 最新の公開コンテンツの状態が公開待ちの場合、コンテンツを返す
    #
    def waiting_content
      content = latest_content
      if content && content.publish? &&
        content.begin_date && content.begin_date > Time.zone.now
        content
      else
        nil
      end
    end

    #
    #=== 編集中のコンテンツを返す
    #
    def editing_content
      original_contents.eq_editing.first
    end

    #
    #=== 公開依頼中のコンテンツを返す
    #
    def request_content
      original_contents.eq_request.first
    end

    #
    #=== 削除可能かどうか返す
    #
    # 下記条件のいずれかを満たす場合、削除不可とする
    #
    # * cancel_page ジョブを持つ
    # * ページの状態が公開中、もちくは公開待ち
    # * ログインユーザが下記の場合
    #   * HP担当者だが、ページの状態が編集中でない
    #
    def deletable?(user)
      if Job.exists?(action: Job::CANCEL_PAGE, arg1: id.to_s)
        return false
      elsif publish_content || waiting_content
        return false
      elsif editing_content
        return true
      elsif user.authorizer_or_admin?
        return true
      else
        return false
      end
    end

    #
    #=== ページのURLの基本パス
    #
    def url_base_path
      genre.present? ? "#{genre.path}#{name}" : ""
    end

    #
    #=== ページのURLパス
    #
    def url_path
      unless genre.nil?
        (name == "index") ? genre.path : "#{url_base_path}.html"
      else
        ""
      end
    end

    #
    #=== URLを取得する
    # フォルダ、ページ名からURLを生成し返却する
    #
    def url
      _url = Settings.base_uri.nil? ? "" : Settings.base_uri.dup
      _url.chop! if _url[-1] == "/"
      _url << url_path
      _url
    end

    #
    #=== 編集のできるPageContentを返す。
    #
    def editable_content
      private_content_or_new
    end

    #
    #=== ロックされているか？
    #
    def locked?(session_id)
      if lock
        lock.expired? ? false : lock.session_id != session_id
      else
        false
      end
    end

    #
    #=== ページのロック
    #
    def lock!(session_id, user)
      self.lock = PageLock.new(
        user_id: user.id,
        session_id: session_id,
        time: Time.now)
      self.save
    end

    #
    #=== ページロック解除
    #
    def unlock!
      self.lock = nil
    end

    #
    #=== 編集履歴追加
    #　revisions　は　id 降順とする
    # 最大履歴数を超える場合は最古の履歴を削除する
    #
    def new_revision(revision)
      self.revisions.last.destroy if self.revisions.count >= Settings.page_revision.limit
      self.revisions << revision
      self.save!
    end

    #
    #=== ページを削除し、ジョブを追加する
    #
    def destroy_with_job
      begin
        self.transaction do
          Job.create(action: Job::DELETE_PAGE, arg1: path.to_s, datetime: Time.zone.now)
          section_news = ::SectionNews.where(page_id: id)
          section_news.destroy! if section_news.present?
          self.destroy!
        end
        true
      rescue => e
        logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        false
      end
    end

    #
    #=== ページのアクセス権限を持つかどうかを返す
    #
    def has_permission?(user)
      genre.has_permission?(user)
    end

    #
    #=== ページが移動可能かどうかを返す
    # 現在公開中、非公開のコンテンツがある場合、移動不可とする
    #
    def movable?
      if visitor_content && visitor_content.end_date && visitor_content.end_date > Time.zone.now
        return false
      else
        return false if waiting_content
      end
      return true
    end

    #
    #=== PageのGenreに紐づくSectionが返る
    #
    def section
      self.genre.try(:section)
    end

    #
    #=== 表示するViewの名前を返す(Visitorで使用)
    #
    def template
      section.present? ? self.section.template : nil
    end

    #
    #=== ページ名を返す
    #
    def basename
      (name || '').sub(%r|.*/(.+)|, '\1')
    end

    #
    #=== GenreのパスとPageのnameを連結した文字列を返す
    #
    def path_base
      "#{self.genre.path}#{self.name}"
    end

    #=== ページのパスを返す
    def path
      g = self.genre
      return '' unless g
      self.name == 'index' ? g.path : "#{self.path_base}.html"
    end

    #=== ツリービューで使用するページのパスを返す
    def path_for_treeview
      path
    end

    #
    #=== news_titleを返す。無ければ、titleを返す
    #
    def news_title
      content = publish_or_latest_content
      if content
        content.news_title.blank? ? self.title : content.news_title
      end
    end

    def rss_create?
      self.publish_content && PageContent::RSS_REGEXP =~ self.publish_content.content
    end

    #
    #=== トップページかどうかを返す
    #
    def top?
      genre.path == '/' && name == 'index'
    end

    #
    #=== 自分のSectionのトップジャンルのパスを返す
    #
    def section_top_genre_path
      top_genre_id = self.section.try(:top_genre_id)
      top_genre_id ? Genre.find_by(id: top_genre_id).try(:path) : nil
    end

    #
    #=== 自身のGenreと同じ階層にあるGenreを全て取得する
    #
    def genres
      ret = []
      self.genre.each_from_parent{ |i| ret << i }
      ret << self.genre
      ret
    end

    #
    #=== 引数のPageContentを編集ページに反映する
    #
    def reflect_editing_content(src, user)
      if waiting_content || (request_content && user.editor?)
        return false
      end
      dest = self.private_content_or_new
      dest.format_version = src.format_version
      dest.content = src.edit_style_content
      dest.mobile  = src.edit_style_mobile_content
      dest.user_name = nil
      dest.tel = nil
      dest.email = nil
      dest.comment = nil
      dest.save_with_normalization(user)
    end

    #
    #=== ページの移動
    # to_genre にページを移動する
    #
    def move_to!(user, to_genre)
      return false unless validate_move(user, to_genre)

      new_path = path.sub(%r|^#{genre.path}|, to_genre.path)
      old_path = path
      begin
        ActiveRecord::Base.transaction do
          Job.create_with(queue: Job.queues[:move_export]).scoping do
            self.genre_id = to_genre.id
            self.save!

            Job.create(action: Job::MOVE_PAGE, arg1: to_genre.path, arg2: old_path.to_s, datetime: Time.now)

            new_page  = Page.find_by_path(new_path)
            from_path = old_path.sub(%r!/\z!, '/index.html').sub(/\.html\z/, '')
            to_path   = new_path.sub(%r!/\z!, '/index.html').sub(/\.html\z/, '')

            page_links = PageLink.where('link LIKE ?', "#{from_path}%").to_a
            page_links.each{|link| link.replace_link_regexp!(%r|^#{Regexp.quote(from_path)}|, to_path)}

            # update links in page_contents.
            page_content_ids = page_links.map(&:page_content_id).uniq.sort
            page_contents = PageContent.where(id: page_content_ids)

            page_ids = page_contents.each do |content|
              content.replace_content_links_regexp(%r|^#{Regexp.quote(from_path)}|, to_path)
              content.save!
            end

            # add page jobs.
            page_ids = page_contents.map(&:page_id).uniq.sort
            pages = Page.where(id: page_ids)

            ([new_page] | pages).compact.each do |page|
              if page.visitor_content
                Job.create(action: Job::CREATE_PAGE, arg1: page.id.to_s, datetime: Time.now)
                page.copies.each do |c|
                  Job.create(action: Job::CREATE_PAGE, arg1: c.id.to_s, datetime: Time.now)
                end
              end
            end

            after_move_to(old_path, new_path)
          end
        end
      rescue => e
        logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        false
      end
    end

    #
    #=== 自身のコピーページを作成する
    #
    def copy
      copy_count = self.copies.present? ? self.copies.size + 1 : 1
      copy_page = self.dup
      copy_page.name  = name + "_#{copy_count}"
      copy_page.title = title + "_#{copy_count}"
      copy_page.original_id = id
      copy_page
    end

    #
    #=== コピーページを保存する
    # コピー元が公開中の場合、ページ作成ジョブを追加する
    #
    def save_copy
      begin
        self.transaction do
          self.save
          if org_publish_content = original.publish_content
            Job.create_page(self, org_publish)
          end
          if org_waiting_content = original.waiting_content
            Job.create_page(self, org_waiting_content)
          end
        end
        true
      rescue =>e
        logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        false
      end
    end

    #
    #=== ページ削除後に不要となるジョブの掃除
    #
    def clean_jobs
      Job.where(["(action = :create_page OR action = :cancel_page) AND arg1 = :id",
                 {create_page: "create_page", cancel_page: "cancel_page", id: self.id.to_s}]).delete_all
    end

    #
    #=== 添付ファイルをディレクトリごと削除する
    #
    def remove_attachment_dir
      FileUtils.rm_rf Rails.root.join('files', Rails.env, id.to_s)
    end

    #
    #=== 詳細画面のURL
    #
    def show_url
      PrefShimaneCms::Application.routes.url_helpers.susanoo_page_path(self.id)
    end

    #
    #=== genre の analytics_code を返す
    #
    def analytics_code
      genre.try(:analytics_code_also_parent)
    end

    #
    #=== latest: true のコンテンツを最新のものだけにする
    # 公開待ちコンテンツがある状態は latest: true が重複するが、
    # 公開待ちコンテンツが公開中になった際は重複を解除する必要がある
    #
    def clear_duplication_latest
      _latests = original_contents
        .where(latest: true)
        .eq_published
        .order(id: :desc)
        .to_a
      _is_correct = (_latests.size <= 1)
      return  if _is_correct
      _latests[1..-1].each do |content|
        content.update_columns(latest: false)
      end
    end

    private

      #
      #=== ページ移動時の検証
      #
      def validate_move(user, to_genre)
        message_scope = 'activerecord.errors.models.page'
        unless has_permission?(user)
          errors.add(:base, I18n.t('no_page_permission', scope: message_scope))
          return false
        end
        unless to_genre.has_permission?(user)
          errors.add(:base, I18n.t('no_genre_permission', scope: message_scope))
          return false
        end
        unless movable?
          errors.add(:base, I18n.t('cannot_move', scope: message_scope))
          return false
        end
        if genre_id == to_genre.id
          errors.add(:base, I18n.t('not_move', scope: message_scope))
          return false
        end
        return true
      end

  end

  module ClassMethods

    #
    #=== Pageインスタンスを無理やり作成している?
    # templateを呼び出すため?
    #
    def index_page(genre)
      page = Page.new(genre_id: genre.id,
                      name: 'index',
                      title: genre.title)
      page.contents << PageContent.new(
        content: "<%= plugin('genre_list') %>\n\n<%= plugin('page_list') %>\n"
      )
      page
    end

    def find_by_path(path)
      path = path + 'index.html' if %r!/\z! =~ path
      genre_path, page_name = path.scan(%r|\A(.*/)([^/]*)\.html\z|).first
      genre = Genre.find_by(path: genre_path)
      return nil unless genre
      return genre.pages.find_by(name: (page_name || 'index'))
    end

    def top_news(genre = nil)
      if genre
        genre.top_news_pages
      else
        Page.joins(:contents).references(:page_contents)
            .where('page_contents.top_news = ?', PageContent.top_news_status[:yes])
            .merge( PageContent.eq_publish ).order('page_contents.begin_date')
      end
    end
  end

  private

    def after_move_to(from_path, to_path)
    end
end
