# -*- coding: utf-8 -*-
#
#== Genre のクラスメソッド、インスタンスメソッドを管理するモジュール
#
module Concerns::Genre::Method
  extend ActiveSupport::Concern

  included do
    before_save :fill_in_attributes
    after_save :update_descendants_path
    after_destroy :clear_section_top_genre
    after_destroy :add_destroy_htpasswd_job
    after_destroy :add_delete_folder_job
    after_destroy :clean_jobs

    # 所属の持つフォルダをIDで検索する.
    # 運用管理者の場合は全フォルダが対象となる
    scope :by_id_and_authority, ->(id, user) {
      if user.admin?
        where(id: id)
      else
        where(id: id, section_id: user.section_id)
      end
    }

    # フォルダ管理画面検索用スコープ
    scope :search, -> (user, genre, options={}) {
      # サブフォルダ再帰検索
      if options[:recursive] == "1"
        scoped = where(["path LIKE ?", "#{genre.path}%"])
        scoped = scoped.where.not(id: genre.id)
      else
        scoped = where(parent_id: genre.id)
      end

      # 運用管理者以外は所属のもつフォルダのみ取得する
      unless user.admin?
        where(section_id: user.section_id)
      end

      # キーワードでname,titleの部分一致を行う
      if options[:keyword].present?
        scoped = scoped.where(
          "title LIKE :keyword OR name LIKE :keyword",
          keyword: "%#{options[:keyword]}%")
      end

      scoped
    }

    scope :user_root, -> (user) {
      if user.admin?
        where(parent_id: nil).order('no ASC, id ASC')
      else
        where(section_id: user.section_id).order('no ASC, id ASC')
      end
    }

    scope :eq_parent_id, -> (genre = nil) {
      if genre.present?
        where(parent_id: genre.parent_id).order('no ASC, id ASC')
      else
        where(parent_id: nil).order('no ASC, id ASC')
      end
    }

    scope :children_of, -> (genre) {
      path = genre.respond_to?(:path) ? genre.path : genre
      path = File.join("#{path}", '/')
      where(arel_table[:path].matches("#{path}%"))
    }

    scope :auth, -> { where(auth: true) }

    #
    #=== フォルダのフルパスの配列を返す
    #
    def fullpath
      _path = ancestors.empty? ? [] : ancestors.reverse
      _path << self
      _path
    end

    #
    #=== オブジェクトの保存前にパラメータを補完する
    #
    def fill_in_attributes
      fill_section_id
      fill_path
    end

    #
    #=== 所有者を設定する
    #
    def fill_section_id
      self.section_id ||= (parent.try(:section_id) || ::Section.super_section_id)
    end

    #
    #=== パスを設定する
    #
    def fill_path
      if name && parent
        self.path = parent.path + name + '/'
      end
    end

    #
    #=== 表示順を設定する
    #
    def fill_no
      maximum = ::Genre.where(parent_id: parent_id).maximum(:no).to_i
      self.no = maximum + 1
    end

    #
    #=== 子孫のパスを更新する
    #
    def update_descendants_path
      top = ::Genre.top_genre
#      children.each {|i| i.save} if top && top.id != id
      if top && top.id != id
        children.each do |i|
          i.path_will_change!
          i.save
        end
      end
    end

    #
    #=== 削除可能なフォルダかどうかを返す
    #
    # 下記条件のいずれかを満たす場合、削除不可とする
    #
    # * deletableフラグのfalse
    # * コピー先のフォルダが存在する
    # * 配下の、はまた配下のフォルダ内のページに削除できないページが存在する
    # * ログインユーザが下記の場合
    #   * HP担当者
    #   * 情報提供責任者だが、対象が異なる所属のフォルダ。または、対象と親の所属が異なる場合。
    #
    def deletable?(user)
      return false unless deletable
      return false if copies.exists?
      return false if descendants_pages.any?{|r| !r.deletable?(user) }

      if user.admin?
        true
      elsif user.authorizer?
        (section_id == user.section_id) && (section_id == self.parent.section_id)
      else
        false
      end
    end

    #
    #== 子フォルダが閲覧できるか？
    #
    def children_deletable?(user)
      user.admin? || self.children.any?{|g| g.section_id == user.section_id }
    end

    #
    #=== 編集可能なフォルダかどうか返す
    # 運用管理者または、ログインユーザとフォルダの所属が同じ場合編集可能とする
    #
    def editable?(user)
      section_id == user.section_id || user.admin?
    end

    #
    #=== 所属トップフォルダを空に設定する
    # 削除時の後処理
    #
    def clear_section_top_genre
      Section.where(top_genre_id: id).update_all(top_genre_id: nil)
    end

    #
    #=== イベント参照を削除する
    # 削除時の後処理
    #
    def delete_event_referer
      ::EventReferer.delete_all(["path like ?", path + "%"])
    end

    #
    #=== トップフォルダか？
    def top_genre?
      self.path == "/"
    end

    #
    #=== フォルダに権限があるかを返す。
    #
    def has_permission?(user)
      user.admin? || self.section_id == user.section_id
    end

    #
    #=== childrenがあるかどうかを返す。
    #
    def has_children?
      self.children.exists?
    end

    #
    #=== フォルダ移動可能であるかを返す。
    #
    # 下記の条件を全て満たす場合に移動可能とする
    #  * 自身のジャンルでアクセス制御が無効である場合
    #  * 下位、上位ジャンルでアクセス制御が有効になっているジャンルが一つもない場合
    #  * 下位ジャンルを含め、全ページが移行可能である場合
    #
    def movable?(options = {})
      if self.auth? ||
          self.class.children_of(self).auth.exists? ||
          ancestors.any?(&:auth?)
        errors.add(:base, :'move.auth')
      end

      if self.descendants_pages.any?{ |page| !page.movable? }
        errors.add(:base, :'move.waiting_page')
      end
    end
    def movable_with_validation?(options = {})
      orig = options[:validate] != true ? errors.messages.dup : nil
      cnt = errors.size

      movable_without_validation?
      errors.size == cnt
    ensure
      if orig
        errors.clear
        errors.messages.update(orig)
      end
    end
    alias_method_chain :movable?, :validation

    #
    #=== 移動更新処理
    #
    def move_to!(to)
      new_path = "#{to.path}#{name}/"
      old_path = path
      begin
        ActiveRecord::Base.transaction do
          Job.create_with(queue: Job.queues[:move_export]).scoping do
            self.parent_id = to.id
            self.no = nil
            self.save!
            Job.create(action: Job::MOVE_FOLDER , arg1: to.path.to_s, arg2: old_path.to_s, datetime: Time.now)
            # def move_genre
            # 移動されるフォルダ内のページにリンクを張っているページのリンクを
            # 書き換えて再公開する。 移動させるフォルダ内のページも再公開される。
            genre = Genre.find_by_path(new_path)
            genre_pages = genre.descendants_pages if genre

            # update links.
            page_links = PageLink.where('link LIKE ?', "#{old_path}%").to_a
            page_links.each{|link|link.replace_link_regexp!(%r|^#{Regexp.quote(old_path)}|, new_path)}

            # update links in page_contents.
            page_content_ids = page_links.map(&:page_content_id).uniq.sort
            page_contents = PageContent.where(id: page_content_ids)

            page_ids = page_contents.each do |content|
              content.replace_content_links_regexp(%r|^#{Regexp.quote(old_path)}|, new_path)
              content.save!
            end

            # add page jobs.
            page_ids = page_contents.map(&:page_id).uniq.sort
            (genre_pages | Page.where(id: page_ids)).compact.each do |page|
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
        true
      rescue
        logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        false
      end
    end

    #
    #=== フォルダ以下の全てのページを取得
    #
    def descendants_pages(include_self = true)
      ret = []
      ret += self.pages if include_self
      children.each { |i| ret += i.descendants_pages }
      ret
    end

    #
    #=== フォルダ以下の全てのフォルダを取得
    #
    def descendants(include_self = true)
      ret = []
      ret << self if include_self
      children.each { |i| ret += i.descendants }
      ret
    end

    #
    #=== フォルダのイテレータ
    #
    def each_ancestor
      ancestors.each do |genre|
        yield genre
      end
    end

    #
    #=== フォルダ作成ジョブを追加する
    #
    def add_create_genre_jobs(include_self = true)
      genres = ancestors
      genres << self if include_self
      genres.each do |g|
        if Genre.root.id != g.id
          Job.create(action: Job::CREATE_GENRE, arg1: g.id.to_s)
        end
      end
    end

    #
    #=== 所属のトップフォルダかどうかを返す
    #
    def section_top?
      id == section.top_genre_id
    end

    #
    #=== htaccess作成または破棄用ジョブを追加する
    #
    def add_auth_job
      ActiveRecord::Base.transaction do
        action = auth ? Job::CREATE_HTACCESS : Job::DESTROY_HTACCESS

        Job.create(:action => action, :arg1 => id.to_s)
        web_monitors.update_all("state = #{WebMonitor.status[:registered]}")
      end
    end

    #
    #===　セクションにトップのジャンルが設定されているか、
    #     自分のセクションIDがSuperSectionではない場合、紐づくSectionを返す
    #
    # 旧:section_except_admin
    def section_except_super
      if self.section.try(:top_genre_id) || self.section_id != Section.super_section_id
        self.section
      end
    end

    #
    #=== 自分の親から自分までをイテレートする
    #
    def each_from_parent
      genre = self
      genres = []
      genres << genre while genre = genre.parent
      genres.reverse!
      genres.each{|g| yield g}
    end

    #=== genreのpathを返す
    # 外部のuriが設定されていれば、外部のuri、なければgenreのpathを返す
    # 主にView側で使用している
    #
    def link_uri
      genre = self.original_id ? Genre.find(self.original_id) : self
      genre.uri.blank? ? genre.path : genre.uri
    end

    #=== section_except_adminで取得した、セクションの名前を返す
    # nilの場合は空文字
    #
    # 旧:section_name_except_admin
    def section_name_except_super
      self.section_except_super.try(:name).to_s
    end

    #===  tracking_codeを返す
    # なければ一つ上の親まで調べる
    #
    def analytics_code_also_parent
      if tc = self.tracking_code
        return tc
      else
        pa = self.parent
        pa ? pa.analytics_code_also_parent : nil
      end
    end

    #
    #===  フォルダ以下の全てのフォルダを取得
    #
    def all_children
      ret = [self]
      self.children.each{|i| ret += i.all_children}
      ret
    end

    #
    #=== フォルダ以下に含まれる全てのPageを取得
    #
    def all_contained_pages
      ret = []
      ret << self.pages
      self.children.each{|i| ret << i.all_contained_pages}
      ret
    end

    #
    #=== フォルダ以下のページで、公開ページを持っていたらtrueを返す
    #
    def has_publish_content?
      all_contained_pages.flatten.any?{|page| page.publish_content}
    end

    #
    #=== 自分から親までの'create_genre'のJobを追加
    #
    def add_genre_jobs_to_parent(self_genre=true)
      genres = ancestors
      genres << self if self_genre
      genres.each do |genre|
        Job.create(action: 'create_genre', arg1: genre.id) if genre.path != '/'
      end
    end

    #
    #=== 通常フォルダかどうか
    #
    def normal?
      true
    end


    #
    #=== コピー可能かどうか
    #
    # 下記の条件を全て満たす場合にコピー可能とする
    #  * 自身のジャンルでアクセス制御が無効である場合
    #  * 下位、上位ジャンルでアクセス制御が有効になっているジャンルが一つもない場合
    #
    def copyable?(options = {})
      res = true

      is_validate = options[:validate] == true
      errors.clear if is_validate

      if self.auth? ||
          self.class.children_of(self).auth.exists? ||
          ancestors.any?(&:auth?)
        errors.add(:base, :'copy/auth') if is_validate
        res = false
      end

      res
    end

    #
    #=== フォルダをコピーする
    #
    def copy!(current_user, to_genre)
      return false unless validate_copy(current_user, to_genre)
      begin
        self.transaction do
          new_genre = self.dup
          new_genre.parent_id = to_genre.id
          new_genre.original_id = id
          new_genre.no = nil
          new_genre.save!
          Job.create(action: Job::CREATE_GENRE, arg1: new_genre.id.to_s)
          copy_page!(self, new_genre)
          children.each_with_index { |c, i| copy_children!(c, new_genre) }
        end
        true
      rescue
        logger.debug(%Q!#{$!} : #{$@.join("\n")}!)
        false
      end
    end

    #
    # 子階層のフォルダをコピーする
    #
    def copy_children!(org_genre, new_parent)
      copy_genre = org_genre.dup
      copy_genre.parent_id = new_parent.id
      copy_genre.original_id = org_genre.id
      copy_genre.path = new_parent.path + copy_genre.name + '/'
      copy_genre.save!
      Job.create(action: Job::CREATE_GENRE, arg1: copy_genre.id.to_s)
      copy_page!(org_genre, copy_genre)
      org_genre.children.each_with_index { |c, i| copy_children!(c, copy_genre) }
    end

    #
    # フォルダ配下のページをコピーする
    #
    def copy_page!(org_genre, new_genre)
      org_genre.pages.each do |org_page|
        new_page = org_page.dup
        new_page.original_id = org_page.id
        new_page.genre_id = new_genre.id
        new_page.save!
        if org_publish = org_page.publish_content
          Job.create_page(new_page, org_publish)
        end
        if org_waiting = org_page.waiting_content
          Job.create_page(new_page, org_waiting)
        end
      end
    end

    #
    #=== フォルダ削除後に不要となるジョブの掃除
    #
    def clean_jobs
      Job.where(["action = :create_genre AND arg1 = :id",
                 {create_genre: "create_genre", id: self.id.to_s}]).delete_all
    end

    #
    #=== フォルダのページで公開しているページがあるか？
    #
    def public_pages_exists?(enable_index_page = false)
      flag = false
      self.pages.each do |page|
        if enable_index_page
          flag = true if page.name == 'index' && page.visitor_content
        else
          flag = true if page.name != 'index' && page.visitor_content
        end
        break if flag
      end
      return flag
    end

    private

      #
      #=== htpasswd ファイルを削除するジョブを追加する
      #
      def add_destroy_htpasswd_job
        if auth
          Job.create(:action => 'destroy_htpasswd', :arg1 => id.to_s)
        end
      end

      #
      #=== フォルダを削除するジョブを追加する
      #
      def add_delete_folder_job
        now = Time.now
        Job.create(action: 'delete_folder', arg1: path.to_s, datetime: now)
        add_create_genre_jobs(false)
        copies.each do |c|
          Job.create(action: 'delete_folder', arg1: c.path.to_s, datetime: now)
          c.add_create_genre_jobs(false)
        end
      end

      #
      #=== コピーの検証を行う
      #
      def validate_copy(user, to_genre)
        message_scope = 'activerecord.errors.models.genre'
        unless has_permission?(user)
          errors.add(:base, I18n.t('org_no_permission', scope: message_scope))
          return false
        end
        unless to_genre.has_permission?(user)
          errors.add(:base, I18n.t('dest_no_permission', scope: message_scope))
          return false
        end
        if to_genre.id == parent_id
          errors.add(:base, I18n.t('no_same_parent', scope: message_scope))
          return false
        end
        descendants.each do |d|
          if d.id == to_genre.id
            errors.add(:base, I18n.t('no_descendants', scope: message_scope))
            return false
          end
        end
        return true
      end
  end

  module ClassMethods
    #
    #=== トップフォルダを返す
    def top_genre
      find_by(path: '/')
    end

    #
    #=== トップレベルのフォルダツリーを返す
    #
    def root_treeview(user, page_displayed: false)
      if user.admin?
        data = build_treeview(user: user, genres: eq_parent_id, show_level: 1, page_displayed: page_displayed)
      else
        genre_group = {}
        genres = where(section_id: user.section_id).order("parent_id, no").select do |g|
          g.parent.nil? || g.parent.section_id != user.section_id
        end
        data = []
        genres.each do |g|
          genealogy = g.ancestors.reverse
          genealogy << g
          data = build_section_genre_tree(user, data, genealogy, page_displayed: page_displayed)
        end
        data
      end
    end

    #
    #=== ログインユーザの所属の持つフォルダでツリービューを作る
    #
    def build_section_genre_tree(user, data, genealogy, page_displayed: false)
      data ||= []
      genre = genealogy.first
      registerd = nil
      data.each { |d| registerd = d if d[:id] == genre.id }

      if registerd.nil?
        new_data = build_treeview(user: user, genres: [genre], page_displayed: page_displayed)
        data += new_data
        registerd = new_data.first
      end

      if genealogy.size > 1
        registerd[:expanded] = true
        registerd[:lazy] = false
        registerd[:children] = build_section_genre_tree(
          user, registerd[:children], genealogy[1..-1], page_displayed: page_displayed)
      end

      data
    end

    #
    #=== 所属の持つフォルダの兄弟要素を返す
    # 運用管理者の場合は全フォルダツリーを表示可能
    #
    def siblings_for_treeview(user, id = nil, page_displayed = false)
      return nil if user.blank?

      genres = if id.nil?
        root_genres(user)
      else
        cond = {parent_id: id}
        cond[:section_id] = user.section_id unless user.admin?
        where(cond).order("no, name")
      end
      #トップレベルのフォルダを表示す場合は１階層下のフォルダも表示する
      if page_displayed && genres.first.nil?
        # ページも表示する場合は、フォルダの中にサブフォルダが無くてページのみ存在する場合もフォルダが展開可能
        # そのため、フォルダを親に持つフォルダ（つまりサブフォルダ）が見つからないのでshow_levelは0にセットする
        show_level = 0
      else
        show_level = (genres.first.parent_id.nil?) ? 1 : 0
      end
      build_treeview(user: user, genres: genres, show_level: show_level, page_displayed: page_displayed)
    end

    #
    #=== フォルダのツリービューを作成する
    #
    def build_treeview(user: user, genres: genres, selected: nil, show_level: 0, current_level: 0, page_displayed: false)
      genres.inject([]) do |a, g|
        title = (g.original) ? "#{g.title}(#{I18n.t('shared.copy')})": g.title
        data = {
          id: g.id,
          title: title,
          folder: true,
          active: (g.id == selected.try(:id)),
          path: g.path,
          expanded: false
        }

        unless user.admin?
          if g.section_id != user.section_id
            data[:no_permission] = true
            data[:extraClasses] = 'unselectable'
          end
        end

        if show_level > current_level &&  (g.children.present? || page_displayed && g.pages.present?)
          data[:expanded] = true
          data[:lazy] = false
          data[:children] = build_treeview(
            user: user, genres: g.children, selected: selected,
            show_level: show_level, current_level: current_level + 1, page_displayed: page_displayed)
          data[:children] += build_treeview_page(g.pages) if page_displayed
        else
          data[:expanded] = false
          data[:lazy] = g.children.present? || page_displayed && g.pages.present?
        end
        a << data
      end
    end

    #
    #=== ページのツリービューを作成する
    #
    def build_treeview_page(pages)
      pages.inject([]) do |a, p|
        a << {
          # idがgenre_idとかぶる可能性がある。ページidとジャンルidを渡すようなイベントを作る場合は注意が必要
          id: p.id,
          title: p.title,
          path: p.path_for_treeview,
          expanded: false,
          extraClasses: "file-html",
        }
      end
    end

    #
    #=== 指定したフォルダまで辿った状態のツリービューを返す
    #
    def selected_treeview(user, selected)
      treedata = Genre.root_treeview(user)
      if selected.present?
        genealogy = selected.ancestors.reverse
        genealogy << selected
        build_selected_treeview(user, treedata, genealogy, selected)
      end
      treedata
    end

    #
    #=== デフォルト表示のツリービューから選択したフォルダまでの道筋を補完する
    #
    def build_selected_treeview(user, data, genealogy, selected = nil)
      genre = genealogy.first
      registerd = nil

      # デフォルトツリービューで未取得の情報を取得する
      data = siblings_for_treeview(user, genre.parent_id) if data.blank?

      data.each { |d| registerd = d if d[:id] == genre.id }

      # 更に末端のフォルダの情報を取得する
      if genealogy.size > 1
        registerd[:expanded] = true
        registerd[:lazy] = false
        registerd[:children] = build_selected_treeview(
          user, registerd[:children], genealogy[1..-1], selected)
      end

      if registerd[:children].present? && selected.present?
        registerd[:children].each { |d| d[:active] = true if d[:id] == selected.id }
      end

      data
    end
    #
    #=== 選択したフォルダのサブフォルダとページを返す
    # 運用管理者の場合は全フォルダツリーを返す.
    #
    def siblings_for_treeview_with_pages(user, id = nil)
      return nil if user.nil?

      genres = siblings_for_treeview(user, id, true)
      return genres if id.nil?  # フォルダを選択していない場合は、siblings_for_treeviewを呼んだのと同じことになる

      pages = Page.where(genre_id: id).order("id")
      genres + build_treeview_page(pages)
    end

    def find_by_name(dir)
      self.find_by(path: dir.sub(%r!/*$!, '/'))
    end

    #
    #===
    #
    def build_treeview_throwback(user, genre, data)
      return data if genre.blank?
      parent_genres = eq_parent_id(genre)
      parent_data = build_treeview(user: user, genres: parent_genres)
      parent_data.each do |d|
        if d[:id] == genre.id
          d[:lazy] = false
          d[:expanded] = true
          d[:children] = data
        end
      end
      if parent.present?
        build_treeview_throwback(user, genre.parent, parent_data)
      else
        parent_data
      end
    end

    private

      #
      #=== ルートフォルダを返す
      # 運用管理者の場合、トップジャンルを返す
      # その他の場合は、所属の持つジャンルのルートジャンルを返す
      #
      def root_genres(user)
        if user.admin?
          where(parent_id: nil).order("id")
        else
          where(section_id: user.section_id).order("id").select do |g|
            g.parent.nil? || g.parent.section_id != user.section_id
          end
        end
      end
  end

  def validate_move(user, to_genre)
    unless has_permission?(user)
      errors.add(:base, :no_genre_permission)
      return false
    end
    unless to_genre.has_permission?(user)
      errors.add(:base, :no_genre_permission)
      return false
    end
    if to_genre.section && to_genre.section.try(:susanoo?) && Section.exists?(top_genre_id: to_genre.id)
      errors.add(:base, :'move.section_top_genre')
      return false
    end
    unless movable?(validate: true)
      return false
    end
    if self.id == to_genre.id
      errors.add(:base, :'move.same_genre')
      return false
    elsif to_genre.ancestors.include?(self)
      errors.add(:base, :'move.ancestor', name: self.title)
      return false
    elsif self.parent_id == to_genre.id
      errors.add(:base, :'move.same_parent')
      return false
    end

    true
  end

  private

    def after_move_to(from_path, to_path)
    end
end

