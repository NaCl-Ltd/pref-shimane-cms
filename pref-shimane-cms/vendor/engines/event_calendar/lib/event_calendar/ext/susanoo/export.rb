Susanoo::Export  # この行が無いとうまく拡張できない
class Susanoo::Export
  def all_page_with_event
    all_page_without_event
    all_event_page
  end
  alias_method_chain :all_page, :event

  def all_event_page
    pages = Page.where("pages.begin_event_date is not NULL AND pages.end_event_date is not NULL").joins(:contents).merge(PageContent.eq_public).uniq
    pages.each do |page|
      next unless page.genre.try(:event?)

      job = Job.find_by(action: 'create_event_page', arg1: page.id.to_s)
      if job && (job.datetime.nil? ||  job.datetime <= Time.now)
        return false
      else
        publish_content = page.publish_content
        if publish_content
          Job.create(action: 'create_event_page', arg1: page.id, datetime: publish_content.begin_date)
          if end_date = publish_content.end_date

            unless Job.exists?(["action = ? AND arg1 = ? AND datetime = ?", 'cancel_event_page', page.id.to_s, end_date])
              Job.create(action: 'cancel_event_page', arg1: page.id, datetime: end_date)
            end
          end
        end
      end
    end
  end

  #
  #=== move_page_with_event_calendar
  #
  # Jobのアクションに'move_page'が入っている時に、sendにより呼び出される
  #
  # args: 移動先パス, 元のパス
  def move_page_with_event_calendar(to_path, from_path)
    res = move_page_without_event_calendar(to_path, from_path)

    page_path = File.join(to_path, File.basename(from_path))
    page = Page.includes(:genre).find_by_path(page_path)
    if page &&
       page.genre.event? &&
       !Job.datetime_is_nil_or_le(Time.zone.now).where(action: 'create_event_page', arg1: page.id.to_s).exists?
      Job.create(action: 'create_event_page', arg1: page.id.to_s, datetime: Time.zone.now)
    end

    # event_info.xml の更新
    if from_event_top = Genre.where(path: "#{File.dirname(from_path)}/").first.try(:event_top)
      xml_creator = ::EventCalendar::Susanoo::Exports::XmlCreator.new(from_event_top.path)
      xml_creator.delete_elements(from_path)
      xml_creator.make
    end

    res
  end
  alias_method_chain :move_page, :event_calendar

  #
  #=== move_folder_with_event_calendar
  #
  # Jobのアクションに'move_folder'が入っている時に、sendにより呼び出される
  #
  # args: 移動先パス, 元のパス
  def move_folder_with_event_calendar(to_path, from_path)
    res = move_folder_without_event_calendar(to_path, from_path)

    all_event_page_under(to_path)

    # event_info.xml の更新
    if from_event_top = Genre.where(path: to_path).first.try(:event_top)
      xml_creator = ::EventCalendar::Susanoo::Exports::XmlCreator.new(from_event_top.path)
      xml_creator.delete_elements_starting_with(from_path)
      xml_creator.make
    end

    res
  end
  alias_method_chain :move_folder, :event_calendar

  # 以下のpluginが埋め込まれたページをcreate_pageするジョブを作成する
  # event_pickup, event_calendar_pickup, event_page_list
  def create_page_for_event_referers
    ::EventReferer.all.each do |ref|
      path = ref.path
      path += 'index.html' if path.last == '/'

      page = Page.find_by_path(path)
      next unless page.try(:publish_content)

      Job.create(action: 'create_page', arg1: page.id)
    end
  end

  private

    def all_event_page_under(path)
      path = path.respond_to?(:path) ? path.path : path
      return if path.blank?
      return unless Genre.exists?(path: File.join(path, '/'))

      pages = Page
        .includes(:genre).references(:genre).merge(Genre.children_of(path))
        .joins(:contents).merge(PageContent.eq_public)
        .where(Page.arel_table[:begin_event_date].not_eq(nil))
        .where(Page.arel_table[:end_event_date].not_eq(nil))
        .uniq
      pages.each do |page|
        next unless page.genre.try(:event?)

        publish_content = page.publish_content
        next unless publish_content.try(:in_publish?)

        unless Job.datetime_is_nil_or_le(Time.zone.now).where(action: 'create_event_page', arg1: page.id.to_s).exists?
          Job.create(action: 'create_event_page', arg1: page.id.to_s, datetime: Time.zone.now)
        end
      end
    end
end
