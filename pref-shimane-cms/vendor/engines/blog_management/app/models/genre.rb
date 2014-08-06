class Genre < ActiveRecord::Base
  include Concerns::Genre::Association
  include Concerns::Genre::Validation
  include Concerns::Genre::Method

  #
  #=== ブログフォルダタイプ
  # * +:none+    - ブログフォルダではない
  # * +:top+     - ブログトップフォルダ
  # * +:year+    - 年フォルダ
  # * +:month+   - 月フォルダ
  #
  @@blog_folder_types = {none: 0, top: 1, year: 2, month: 3}.with_indifferent_access

  def normal_with_blog_management?
    normal_without_blog_management? && !self.blog_folder?
  end

  alias_method_chain :normal?, :blog_management

  cattr_reader :blog_folder_types

  scope :blog_top_in_section, -> (section) {
    scoped = ::Genre
    scoped = scoped.where(blog_folder_type: self.blog_folder_types[:top])
    scoped = scoped.where(section_id: section.id)
    scoped
  }

  #
  #=== ブログフォルダ以下に、年フォルダ、そのさらに下に月フォルダを作成
  #
  def create_year_month_folder!(date = Date.today)
    attributes = self.attributes.symbolize_keys.slice(:section_id)

    # yyyyというフォルダ名のレコードを作成する
    year = date.year.to_s
    year_folder = self.children.where(:name => year).first
    unless year_folder
      year_foloder_attributes = attributes.merge(name: year, title: year, blog_folder_type: Genre.blog_folder_types[:year])
      year_folder = self.children.build(year_foloder_attributes)
      year_folder.save!
      ::Job.create(action: ::Job::CREATE_GENRE, arg1: year_folder.id.to_s)
    end

    # mmというフォルダ名のレコードを作成する
    month = date.month.to_s
    month_folder = year_folder.children.where(:name => month).first
    unless month_folder
      month_folder_attributes = attributes.merge(name: month, title: month, blog_folder_type: Genre.blog_folder_types[:month])
      month_folder = year_folder.children.build(month_folder_attributes)
      month_folder.save!
      ::Job.create(action: ::Job::CREATE_GENRE, arg1: month_folder.id.to_s)
    end
  end

  def blog_folder?
    self.blog_folder_type && self.blog_folder_type != Genre.blog_folder_types[:none]
  end

  def blog_top_folder
    case self.blog_folder_type
    when Genre.blog_folder_types[:top]
      self
    when Genre.blog_folder_types[:year]
      self.parent
    when Genre.blog_folder_types[:month]
      self.parent.parent
    else
      nil
    end
  end

  def blog_top_folder?
    self.blog_folder_type == Genre.blog_folder_types[:top]
  end

  #
  #=== フォルダ期間内のブログページのidを返す
  #
  def blog_page_ids
    return [] unless self.blog_folder?

    case self.blog_folder_type
    when Genre.blog_folder_types[:top]
      self.children.where(blog_folder_type: Genre.blog_folder_types[:year]).map do |year_genre|
        year_genre.blog_page_ids
      end
    when Genre.blog_folder_types[:year]
      self.children.where(blog_folder_type: Genre.blog_folder_types[:month]).map do |month_genre|
        month_genre.blog_page_ids
      end
    when Genre.blog_folder_types[:month]
      self.pages.where.not(blog_date: nil).select(:id).map(&:id)
    end.flatten
  end

  #
  #=== 次月移行で、公開中のページコンテンツが存在している直近の月フォルダを取得する
  #
  def next_month
    next_or_prev_month("next")
  end

  #
  #=== 前月以前で、公開中のページコンテンツが存在している直近の月フォルダを取得する
  #
  def prev_month
    next_or_prev_month("prev")
  end

  def validate_move_with_blog_system(user, to_genre)
    res = validate_move_without_blog_system(user, to_genre)
    return res unless res  # 既に失敗していた場合は、何も行わず結果のみ返す

    if self.blog_folder?
      # ブログトップフォルダを他のフォルダへの移動は許可する
      unless self.blog_top_folder? && !to_genre.blog_folder?
        errors.add(:base, :'move.src_blog_folder')
        return false
      end
    elsif to_genre.blog_folder?
      errors.add(:base, :'move.dest_blog_folder')
      return false
    end

    res
  end
  alias_method_chain :validate_move, :blog_system

  private

  #
  #=== 次月以降、または前月以前で公開しているページがある直近の月フォルダを返す
  #
  def next_or_prev_month(mode)
    return nil unless self.blog_folder_type == Genre.blog_folder_types[:month]

    visitor_content = nil
    date = Time.new(self.parent.name.to_i, self.name.to_i, 1)
    scope = Page.where(id: self.parent.parent.blog_page_ids)
    case mode
    when "next"
      scope = scope.where(["blog_date >= ?", date.next_month.beginning_of_month]).order("blog_date asc")
    when "prev"
      scope = scope.where(["blog_date <= ?", date.prev_month.end_of_month]).order("blog_date desc")
    end

    scope.each do |page|
      visitor_content = page.visitor_content
      break if visitor_content
    end

    return nil unless visitor_content
    visitor_content.page.genre
  end
end
