require 'rss'

module Susanoo
  module Exports

    #
    #= RSSを作成するクラス
    #
    class RssCreator < Creator::Base

      #
      #=== 初期化
      #
      def initialize(page, item_resources)
        @page = page
        @item_resources = item_resources
      end

      #
      #=== RSSを作成するして、書き込む
      #
      def make
        rss = RSS::Maker.make('2.0') do |maker|
          maker.channel.title = I18n.t('rss.title', title: @page.title)
          maker.channel.description = I18n.t('rss.description')
          maker.channel.link = Settings.public_uri

          @item_resources[0 ... 10].each do |item_resource|
            publish_content = item_resource.try(:visitor_content)
            next unless publish_content  # 現在公開中のページに限定

            item = maker.items.new_item

            item.title = publish_content.try(:news_title) ? publish_content.news_title : @page.title
            item.link = "#{Settings.public_uri.chop}#{item_resource.path}"
            item.description = content_truncate(publish_content.try(:content))
          end
        end
        rss_write_path = path_with_type(@page.path, :rss)
        write_file(rss_write_path, rss.to_s)
      end

      private

        #
        #=== コンテンツをスクレイピングして取得し、トランケートして返す
        #
        def content_truncate(content, selector='p', truncate_count=200)
          if content.present?
            html = Nokogiri::HTML(content)
            html.css(selector).map(&:content).join.truncate(truncate_count)
          else
            ''
          end
        end
    end

  end
end
