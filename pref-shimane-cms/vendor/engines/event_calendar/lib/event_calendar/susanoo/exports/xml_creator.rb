module EventCalendar
  module Susanoo
    module Exports
      class XmlCreator < ::Susanoo::Exports::Creator::Base

        #
        #=== 初期化
        #
        def initialize(path)
          @xml_path = Pathname(path).join("event_info.xml")
          @docroot_xml_path = Pathname(File.join(Settings.export.docroot, @xml_path))
          unless File.exists?(@docroot_xml_path)
            builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
              xml.events
            end
            write_file(@xml_path, builder.to_xml)
          end
          @doc = Nokogiri::XML(open(@docroot_xml_path))
        end

        #
        #=== 該当イベントの要素をxmlから削除する
        #
        def delete_elements(page)
          path = page.respond_to?(:path) ? page.path : page
          @doc.xpath("//events/event[@address='#{path}']").each do |event|
            event.remove
          end
        end

        #
        #=== 該当イベントの要素をxmlから削除する
        #
        def delete_elements_starting_with(page)
          path = page.respond_to?(:path) ? page.path : page
          @doc.xpath("//events/event[starts-with(@address, '#{path}')]").each do |event|
            event.remove
          end
        end

        #
        #=== 該当イベントの開催期間分の要素をxmlに追加する
        #
        def add_elements(page)
          (page.begin_event_date .. page.end_event_date).each do |date|
            event_node = Nokogiri::XML::Node.new "event", @doc
            event_node["address"] = page.path
            date_node = Nokogiri::XML::Node.new "date", @doc
            date_node.content = "#{date.year}-#{date.month}-#{date.day}"
            event_node.add_child(date_node)
            @doc.at("//events").add_child(event_node)
          end
        end

        #
        #=== XMLファイルを作成する
        #
        def make
          write_file(@xml_path, @doc.to_xml)
          sync_docroot(@xml_path.to_s)
        end

        #
        #=== XMLファイルの内容を返す
        #
        def body
          @doc.to_xml
        end
      end
    end
  end
end
