class Page < ActiveRecord::Base
  include Concerns::Page::Association
  include Concerns::Page::Validation
  include Concerns::Page::Method

  attr_accessor :blog_top_genre_id
  before_validation :generate_blog_folder_and_set_genre_id_and_name,
                      if: lambda { self.blog_top_genre_id && self.blog_date }
  before_create :generate_blog_genre_page,
                      if: lambda { self.blog_top_genre_id && self.blog_date }

  scope :search_for_blog, -> (genre, opt={}) {
    s = PageContent.page_status
    g = Genre.arel_table
    p = Page.arel_table
    c = PageContent.arel_table

    r = Page.includes(:genre, :contents)

    # pages.blog_dateがあるかどうか
    r = r.where(p[:blog_date].not_eq(nil))

    # pagesのジャンルのblog_folder_typeがmonthであるかどうか
    r = r.where(g[:blog_folder_type].eq(Genre.blog_folder_types[:month]))

    # キーワードでname,titleの部分一致を行う
    if opt[:keyword].present?
      key = "%#{opt[:keyword]}%"
      r = r.where(p[:title].matches(key).or(p[:name].matches(key)))
    end

    # サブフォルダ再帰検索
    if opt[:recursive] != '1'
      r = r.where(p[:genre_id].eq(genre.id))
    else
      r = r.where(g[:path].matches("#{genre.path}%"))
    end

    if (opt[:admission].present? && [s[:waiting],s[:publish],s[:finished],s[:cancel]].include?(opt[:admission]))
      r = r.where(c[:latest].eq(true))
    end

    # 公開待ち、公開中、公開期限切れを指定した場合
    # PageContentのbegin_date(公開開始日)とend_date(公開終了日)から公開状態を判定する
    if opt[:admission].present?
      now = Time.zone.now
      case opt[:admission]
      when s[:editing], s[:request], s[:reject],s[:cancel]
        r = r.where(c[:admission].eq(opt[:admission]))
      when s[:waiting]
        r = r.where(c[:admission].eq(s[:publish]))
        r = r.where(c[:begin_date].not_eq(nil).and(c[:begin_date].gt(now)))
      when s[:publish]
        r = r.where(c[:admission].eq(s[:publish]))
        r = r.where(c[:begin_date].eq(nil).or(c[:begin_date].lteq(now)))
        r = r.where(c[:end_date].eq(nil).or(c[:end_date].gt(now)))
      when s[:finished]
        r = r.where(c[:admission].eq(s[:publish]))
        r = r.where(c[:end_date].not_eq(nil).and(c[:end_date].lteq(now)))
      end
    end
    r = r.where(["pages.blog_date >= ?", opt[:start_at]]) if opt[:start_at].present?
    r = r.where(["pages.blog_date <= ?", opt[:end_at]]) if opt[:end_at].present?
    r.references([:contents, :genre])
  }

  def blog_top_folder
    return "" if self.genre.blog_folder_type != Genre.blog_folder_types[:month]
    self.genre.parent.parent
  end

  # ブログページ(日付.html)または、ブログトップ、年、月のインデックスページかどうか
  def blog_page_or_index?
    self.blog_date? || (self.name == "index" && self.genre.blog_folder?)
  end

  def add_blog_index_page_jobs(begin_date = Time.now)
    # self.page.genreの前月以前で、最新の公開ページがあるジャンル（月）を取得する
    # そのジャンルのindexページと、親（年）ジャンルのインデックスページに対して、create_pageの
    # Jobを追加する。
    prev_month_genre = self.genre.prev_month
    if prev_month_genre
      if prev_month_page = prev_month_genre.pages.where(name: "index").first
        prev_month_page.add_blog_index_page_job(begin_date)
      end
      if prev_month_genre.parent
        if prev_year_page = prev_month_genre.parent.pages.where(name: "index").first
          prev_year_page.add_blog_index_page_job(begin_date)
        end
      end
    end

    # self.page.genreの次月以降で、最新の公開ページがあるジャンル（月）を取得する
    # そのジャンルのindexページと、親（年）ジャンルのインデックスページに対して、create_pageの
    # Jobを追加する。
    next_month_genre = self.genre.next_month
    if next_month_genre
      if next_month_page = next_month_genre.pages.where(name: "index").first
        next_month_page.add_blog_index_page_job(begin_date)
      end
      if next_month_genre.parent
        if next_year_page = next_month_genre.parent.pages.where(name: "index").first
          next_year_page.add_blog_index_page_job(begin_date)
        end
      end
    end

    # ブログトップ（インデックス）ページをcreate_pageするJobを追加する
    if self.genre.blog_top_folder
      if top_page = self.genre.blog_top_folder.pages.where(name: "index").first
        top_page.add_blog_index_page_job(begin_date)
      end
    end
  end

  def add_blog_index_page_job(begin_date = Time.now)
    Job.create(action: Job::CREATE_PAGE, arg1: self.id.to_s, datetime: begin_date)
  end


  def rss_create_with_blog?
    rss_create_without_blog? || self.genre.blog_folder_type == ::Genre.blog_folder_types[:top]
  end

  alias_method_chain :rss_create?, :blog

  def show_url_with_blog
    if self.blog_date?
      BlogManagement::Engine.routes.url_helpers.susanoo_page_path(self.id)
    else
      show_url_without_blog
    end
  end
  alias_method_chain :show_url, :blog

  def validate_move_with_blog_system(user, to_genre)
    res = validate_move_without_blog_system(user, to_genre)
    return res unless res  # 既に失敗していた場合は、何も行わず結果のみ返す

    if self.blog_page_or_index?
      errors.add(:base, :'move.blog_page_or_index')
      return false
    elsif to_genre.blog_folder?
      errors.add(:base, :'move.dest_blog_folder')
      return false
    end

    res
  end
  alias_method_chain :validate_move, :blog_system

  private

  def generate_blog_folder_and_set_genre_id_and_name
    genre = Genre.find(self.blog_top_genre_id)
    genre.create_year_month_folder!(self.blog_date)
    self.genre_id ||= genre.children.where(name: self.blog_date.year.to_s).first.children.where(name: self.blog_date.month.to_s).first.id
    self.name ||= self.blog_date.day.to_s
  end

  def generate_blog_genre_page
    # 月フォルダのindexページを作成
    attr = {genre_id: self.genre_id, name: "index"}
    Page.create! attr.merge(title: "month_index") unless Page.exists? attr

    # 年フォルダのindexページを作成
    attr = {genre_id: self.genre.parent_id, name: "index"}
    Page.create! attr.merge(title: "year_index") unless Page.exists? attr

    # ブログトップフォルダのindexページを作成
    attr = {genre_id: self.genre.parent.parent_id, name: "index"}
    Page.create! attr.merge(title: "blog_index") unless Page.exists? attr
  end
end
