require 'spec_helper'

describe Susanoo::Exports::QrCodeCreator do
  describe "メソッド" do
    describe "#initialize" do
      let(:page) { create(:page_publish) }
      let(:item_resources) { [create(:page_publish)] }

      before do
        @rss_creator = Susanoo::Exports::RssCreator.new(page, item_resources)
      end

      it "@pageに正しい値が設定されていること" do
        expect(@rss_creator.instance_eval{ @page }).to eq(page)
      end

      it "@item_resourcesに正しい値が設定されていること" do
        expect(@rss_creator.instance_eval{ @item_resources }).to eq(item_resources)
      end
    end

    describe "#make" do
      let(:page) { create(:page_publish) }
      let(:item_resources) { [create(:page_publish)] }

      before do
        @rss_creator = Susanoo::Exports::RssCreator.new(page, item_resources)

        @rss = RSS::Maker.make('2.0') do |maker|
          maker.channel.title = I18n.t('rss.title', title: page.title)
          maker.channel.description = I18n.t('rss.description')
          maker.channel.link = Settings.public_uri

          item_resources.each do |item_resource|
            item = maker.items.new_item

            publish_content = item_resource.publish_content
            item.title = page.title
            item.link = "#{Settings.public_uri.chop}#{item_resource.path}"

            html = Nokogiri::HTML(publish_content.content)
            item.description = html.css('p').map(&:content).join
          end
        end
      end

      it "期待したRSSをファイルに書き出していること" do
        path = Pathname.new("#{page.genre.path}#{page.name}.rdf")
        expect_any_instance_of(Susanoo::Exports::RssCreator).to receive(:write_file).with(path, @rss.to_s)
        @rss_creator.make
      end
    end

    describe "#content_truncate" do
      let(:page) { create(:page_publish) }
      let(:item_resources) { [create(:page_publish)] }

      before do
        @rss_creator = Susanoo::Exports::RssCreator.new(page, item_resources)
      end

      context "pタグの中身が200文字以上の場合" do
        before do
          @str = ''
          300.times{|i| @str << i.to_s}
        end

        it "truncateされたコンテンツが返ること" do
          expect(@rss_creator.send(:content_truncate, "<p>#{@str}</p>")).to eq(@str.truncate(200))
        end
      end
    end
  end
end
