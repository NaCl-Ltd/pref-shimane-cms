module EventCalendar
  module PluginHelper
    def PluginHelper.event_month(args)
      path = args[0]
      events = Hash.new{|h, key| h[key] = [] }
      categories = Array.new
      args[1] =~ /(\d\d\d\d)-(\d\d|\d)/
      range_begin = Date.new($1.to_i, $2.to_i, 1)
      range_end = Date.new($1.to_i, $2.to_i, -1)

      event_calendar_genre = nil
      event_top = ::Genre.find_by_path(path)
      pages = ::Page.search_for_event(event_top, recursive: "1", admission: PageContent.page_status[:publish], start_at: range_begin, end_at: range_end)
      event_contents = pages.map{ |page| page.publish_content }.compact
      event_contents.each { |event_content|
        address = event_content.page.path
        title = event_content.page.title
        category = event_content.page.genre.event_category
        date = event_content.page.begin_event_date
        while (date <= range_end && date <= event_content.page.end_event_date)
          if date >= range_begin
            day = date.day.to_i
            events["#{category.title}"] << [title, address, day]
            if category.event_top?
              event_calendar_genre = [category.title, category.name]
            else
              categories << [category.title, category.name]
            end
          end
          date += 1
        end
      }
      categories.uniq!
      sorted_categories = categories.sort_by{ |category|  category[1]}
      sorted_categories << event_calendar_genre  unless event_calendar_genre.nil?
      sorted_categories.each do |cat|
        events["#{cat[0]}"].sort!{ |i,j|
          contrast = i[2] <=> j[2]
          if contrast == 0
            i[1] <=> j[1]
          else
            contrast
          end
        }
      end
      return events, sorted_categories.collect{|category|  category[0]}
    end

    def PluginHelper.event_day(args)
      path = args[0]
      event_date = Date.parse(args[1])
      events = Hash.new{|h, key| h[key] = [] }
      categories = Array.new

      event_calendar_genre = nil
      event_top = ::Genre.find_by_path(path)
      pages = ::Page.search_for_event(event_top, recursive: "1", admission: PageContent.page_status[:publish], start_at: event_date, end_at: event_date)
      event_contents = pages.map{ |page| page.publish_content }.compact
      event_contents.each{ |event_content|
        address = event_content.page.path
        title = event_content.page.title
        category = event_content.page.genre.event_category
        events["#{category.title}"] << [title, address]
        if category.event_top?
          event_calendar_genre = [category.title, category.name]
        else
          categories << [category.title, category.name]
        end
      }
      categories.uniq!
      sorted_categories = categories.sort_by{ |category|  category[1]}
      sorted_categories << event_calendar_genre  unless event_calendar_genre.nil?
      for category in sorted_categories
        events["#{category[0]}"].sort!{ |i,j|
          i[1] <=> j[1]
        }
      end
      return events, sorted_categories.collect{|category|  category[0]}
    end

    def PluginHelper.event_pickup(path, range_begin, range_end)
      event_top = Genre.find_by_path(path)
      return [] unless event_top
      pages = ::Page.search_for_event(event_top, recursive: "1", admission: PageContent.page_status[:publish], start_at: range_begin, end_at: range_end)
      event_contents = pages.map{ |page| page.publish_content }.compact
      event_contents.sort_by{ |content|
        if content.begin_event_date == Date.today
          Date.new(1959,1,25).to_s + content.end_event_date.to_s
        else
          content.begin_event_date.to_s + content.end_event_date.to_s
        end
      }
    end
  end
end
