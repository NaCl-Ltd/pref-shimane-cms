module Susanoo::PluginHelper
  def top_news(args)
    news_genre = nil
    if !args.empty? && args.last =~ %r!(/[^/]+)+/!
      news_genre = Genre.find_by_path(args.pop)
      Page.top_news(args, news_genre)
    else
      Page.top_news(args)
    end
  end


  def emergency_exist?
    if genre = Genre.find_by_path(Settings.emergency_path)
      @emergency_exist = SectionNews.like_path("#{genre.path}%").any?
    else
      false
    end
  end

  def max_count(args)
    args.first.to_i.zero? ? 9 : args.first.to_i - 1
  end


  def show_section_news_title?(args)
    if args.include?("on")
      args.reject!{ |i| i == "on" }
      return true
    end
    return false
  end

  def show_genre_news_title?(args)
    if args.include?("off")
      args.reject!{ |i| i == "off" }
      return false
    end
    return true
  end

  def genre_news_list(args, genre)
    page_content_list =
      SectionNews.includes(:page).where("path like ?", "#{genre.path}%")
        .order('begin_date desc')
    if args[1] && !args[1].to_i.zero?
      max_date = args[1].to_i * 60 * 60 * 24
      page_content_list.reject! do |e|
        (Time.now - e.begin_date) > max_date ? true : false
      end
    end

    # 現在公開されているページに限定
    page_content_list = page_content_list.select{|n| n.page.try(:visitor_content) }

    return page_content_list
  end

  def rubi?
    cookies['ruby'] && cookies['ruby'].first == 'on'
  end

  #
  #=== 指定したパス、期間の新着情報を返す
  #
  def genre_news(arg, max, max_date)
    condition = []
    news = []
    if arg == 'all'
      news = SectionNews.top_with_max_date(max_date)
    elsif arg == 'other'
      news = SectionNews.others_with_max_date(max_date)
    else
      news = SectionNews.under_path_with_max_date(arg, max_date)
    end

    # 現在公開されているページに限定
    news = news.reorder('begin_date DESC').includes(:page).select{|n| n.page.try(:visitor_content) } unless news.empty?

    return news[0..max] unless news.empty?
    return nil
  end
end

