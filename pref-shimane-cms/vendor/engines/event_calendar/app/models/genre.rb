class Genre < ActiveRecord::Base
  include Concerns::Genre::Association
  include Concerns::Genre::Validation
  include Concerns::Genre::Method

  after_destroy :delete_db_event_referer_for_folder

  #
  #=== イベントフォルダタイプ
  # * +:none+    - イベントフォルダではない
  # * +:top+     - イベントトップフォルダ
  # * +:genre+   - イベントジャンルフォルダ
  #
  @@event_folder_types = {none: 0, top: 1, category: 2}.with_indifferent_access

  def normal_with_event_calendar?
    normal_without_event_calendar? && !self.event?
  end

  alias_method_chain :normal?, :event_calendar

  cattr_reader :event_folder_types

  scope :event_top_in_section, -> (section) {
    scoped = ::Genre
    scoped = scoped.where(event_folder_type: self.event_folder_types[:top])
    scoped = scoped.where(section_id: section.id)
    scoped
  }

  def event?
    self.event_folder_type == ::Genre.event_folder_types[:top] || self.event_folder_type == ::Genre.event_folder_types[:category]
  end

  def event_top
    case self.event_folder_type
    when ::Genre.event_folder_types[:top]
      self
    when ::Genre.event_folder_types[:category]
      self.parent.event_top
    else
      nil
    end
  end

  def event_top?
    self.event_folder_type == self.event_folder_types[:top]
  end

  # イベントトップではなく、かつカテゴリである。カテゴリのサブフォルダはfalse
  def event_category_top?
    self.event_folder_type == self.event_folder_types[:category] && self.parent.event_top?
  end

  # イベントトップであれば、自身を返す
  # 親がイベントトップであれば、自身を返す
  def event_category
    return self if self.event_top?
    return self if self.parent.event_top?
    return nil  if self.path == '/'
    self.parent.event_category
  end

  # イベントの、年、月、日の各インデックス(フォルダ、またはページへ）のパスを返す
  def event_index_path(year: nil, month: nil, day: nil)
    _path = self.event_top.path
    _path += "#{year.to_s}/" if year
    _path += "#{month.to_s}/" if year && month
    _path += "#{day.to_s}.html"  if year && month && day
    _path
  end

  # /top/event/2012/12のようなパスが、イベントのインデックスのパスであるか判定する
  # イベントのインデックス用のジャンルやページがDB上に存在しないため、このようなメソッドが必要
  def self.event_index_path?(path)
    if path =~ %r!(.*/)\d\d\d\d! && _genre = ::Genre.find_by_path($1)
      return _genre.event_folder_type == ::Genre.event_folder_types[:top]
    end
    false
  end

  # ジャンル削除時に、そのジャンル以下にあるイベント参照ページのevent_referersを削除する
  def delete_db_event_referer_for_folder
    ::EventReferer.delete_all(["path like ?", path + "%"])
  end

  def validate_move_with_event_calendar(user, to_genre)
    res = validate_move_without_event_calendar(user, to_genre)

    return res unless res  # 既に失敗していた場合は、何も行わず結果のみ返す

    from_event_top = self.event_top
    to_event_top = to_genre.event_top

    # 移動元、移動先がどちらもイベントフォルダでない場合、
    # イベントフォルダとしての検証を行わない
    return res unless from_event_top || to_event_top

    if from_event_top && !to_event_top
      # イベントトップフォルダを他のフォルダへの移動は許可する。
      unless self.path == from_event_top.path
        errors.add(:base, :'move.dest_not_event_calendar')
        return false
      end
    elsif !from_event_top && to_event_top
      errors.add(:base, :'move.src_not_event_calendar')
      return false
    elsif from_event_top.path != to_event_top.path
      errors.add(:base, :'move.same_event_top_calendar')
      return false
    end

    res
  end
  alias_method_chain :validate_move, :event_calendar

  private

    def after_move_to_with_event_calendar(from_path, to_path)
      after_move_to_without_event_calendar(from_path, to_path)

      # Page
      target_path_ers = ::EventReferer.where('event_referers.target_path LIKE :path', path: "#{from_path}%")
      page_paths = target_path_ers.map{|er| er.path.sub(%r{/$}, '/index.html') }
      pages = Page.joins(:genre).where(name: page_paths.map{|path| File.basename(path, '.html')}).where('genres.path' => page_paths.map{|path| "#{File.dirname(path)}/"})
      pages.each do |page|
        if pc = page.publish_content
          ::EventReferer.plugin_regexp.values.each do |plugin_regexp|
            if pc.content
              pc.content = pc.content.gsub(plugin_regexp) do |str|
                str.gsub(plugin_regexp) do |s|
                  if $1  # target_path specified
                    s[*$~.offset(1)] = s[*$~.offset(1)].sub(/^#{Regexp.quote(from_path)}/, to_path)
                  end
                  s
                end
              end
            end
            if pc.mobile
              pc.mobile = pc.mobile.gsub(plugin_regexp) do |str|
                str.gsub(plugin_regexp) do |s|
                  if $1  # target_path specified
                    s[*$~.offset(1)] = s[*$~.offset(1)].sub(/^#{Regexp.quote(from_path)}/, to_path)
                  end
                  s
                end
              end
            end
          end
          target_path_ers.delete_all
          pc.save!  # EventReferer will be registed on PageContent's save callback.
        end
      end

      path_ers = ::EventReferer.where('event_referers.path LIKE :path', path: "#{from_path}%'")
      path_ers.each do |er|
        er.path = er.path.sub(/^#{Regexp.quote(from_path)}/, to_path)
        er.save!
      end

      event_top_genres = Genre.where(path: [from_path, to_path]).to_a.compact.map(&:event_top).compact.uniq
      update_page_ers = ::EventReferer.where(event_top_genres.map{ 'event_referers.target_path LIKE ?' }.join(' OR '), *event_top_genres.map(&:path))
      page_paths = update_page_ers.map{|er| er.path.sub(%r{/$}, '/index.html') }.uniq
      pages = Page.joins(:genre).where(name: page_paths.map{|path| File.basename(path, '.html')}).where('genres.path' => page_paths.map{|path| "#{File.dirname(path)}/"})
      pages = pages.index_by(&:path).values_at(*page_paths).compact

      pages.each do |page|
        if page.visitor_content
          Job.find_or_create_by(datetime: Time.zone.now, action: Job::CREATE_PAGE, arg1: page.id.to_s)
        end
      end
    end
    alias_method_chain :after_move_to, :event_calendar
end
