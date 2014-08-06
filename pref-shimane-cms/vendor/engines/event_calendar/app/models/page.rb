class Page < ActiveRecord::Base
  include Concerns::Page::Association
  include Concerns::Page::Validation
  include Concerns::Page::Method

  attr_accessor :event_top_id

  before_validation :assign_event_top_id_to_genre_id,
                      :if => lambda { self.event_top_id.present? && self.genre_id.blank? }

  validate do |r|
    if r.begin_event_date.present? && r.end_event_date.present?
      # イベントの開始と終了の範囲がが30日より大きい場合
      count = 30
      if (r.end_event_date - r.begin_event_date).to_i > count
        r.errors.add(:base, :invalid_date_range, count: count)
      end

      # イベントの開始と終了の日付が逆転している場合
      if r.begin_event_date > r.end_event_date
        r.errors.add(:base, :reverse_date)
      end
    end
  end

  scope :search_for_event, -> (genre, opt={}) {
    s = ::PageContent.page_status
    g = Genre.arel_table
    p = Page.arel_table
    c = PageContent.arel_table

    r = Page.includes(:genre, :contents)

    # genres.event_folder_typeが、::Genre.event_folder_types[:top]または::Genre.event_folder_types[:genre]かどうか
    r = r.where(g[:event_folder_type].in([::Genre.event_folder_types[:top], Genre.event_folder_types[:category]]))

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
    r = r.where(["pages.begin_event_date <= ?", opt[:end_at]]) if opt[:end_at].present?
    r = r.where(["pages.end_event_date >= ?", opt[:start_at]]) if opt[:start_at].present?
    r.references([:contents, :genre])
  }

  #
  # イベントページを返す
  #
  def event?
    self.genre.event?
  end

  #
  # イベントページのトップフォルダを返す
  #
  def event_top
    return nil unless self.event?
    self.genre.event_top
  end

  # イベントページであれば、自身のジャンル、もしくはその親たちの中で、最初に見つけたイベントトップフォルダ、またはカテゴリフォルダを返す
  def event_category
    return nil unless self.event?
    _genre = self.genre
    while(!_genre.event?)
      return nil unless _genre.parent
      _genre = _genre.parent
    end
    _genre
  end

  def show_url_with_event
    if self.event?
      EventCalendar::Engine.routes.url_helpers.susanoo_page_path(self.id)
    else
      show_url_without_event
    end
  end
  alias_method_chain :show_url, :event

  def validate_move_with_event_calendar(user, to_genre)
    res = validate_move_without_event_calendar(user, to_genre)

    return res unless res  # 既に失敗していた場合は、何も行わず結果のみ返す

    from_event_top = self.event_top
    to_event_top = to_genre.event_top

    # 移動元、移動先がどちらもイベントフォルダでない場合、
    # イベントフォルダとしての検証を行わない
    return res unless from_event_top || to_event_top

    if from_event_top && !to_event_top
      errors.add(:base, :'move.dest_not_event_calendar')
      return false
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

    def assign_event_top_id_to_genre_id
      self.genre_id = self.event_top_id.to_i
    end

    def after_move_to_with_event_calendar(from_path, to_path)
      after_move_to_without_event_calendar(from_path, to_path)

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

      event_top_genres = Genre.where(path: [File.dirname(from_path), File.dirname(to_path)]).to_a.compact.map(&:event_top).compact.uniq
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
