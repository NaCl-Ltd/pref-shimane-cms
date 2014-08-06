require 'spec_helper'

describe Genre do
  describe "メソッド" do
    describe "#regist" do
      let(:genre) { create(:top_genre) }
      let(:page)  { create(:page, genre: genre) }


      context "イベントツールプラグインがある場合" do
        subject {
          create(:page_content_publish, page: page, content:
                 %Q|<%= plugin('event_calendar_pickup', '/event/', '5') %>|)
        }

        it "event_referersレコードが1件増えること" do

          expect{subject}.to change(EventReferer, :count).by(1)
        end
      end

      context "イベントツールプラグインがない場合" do
        subject { EventReferer.regist(page.path) }

        before do
          create(:page_content_publish, page: page, content: "plugin")
        end

        it "event_referersレコードが1件増えないこと" do
          expect{subject}.to change(EventReferer, :count).by(0)
        end
      end
    end
  end
end
