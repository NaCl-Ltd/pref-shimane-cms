require 'spec_helper'

describe SectionNews do
  describe "メソッド" do
    describe ".create_news_pages" do
      let(:top_genre) { create(:top_genre) }

      context "pageのパスが'/'の場合" do
        let(:page) { create(:page, genre_id: top_genre.id) }
        let!(:page_top_news) { [create(:page_publish_top_news)] }

        it "トップニュースが含まれるページを返すこと" do
          expect(SectionNews.create_news_pages(top_genre)).to eq(page_top_news)
        end
      end

      context "ページが所属のトップページの場合" do

        before do
          section = create(:section)
          genres = create_list(:genre, 3, parent_id: top_genre.id, section_id: section.id)

          section.top_genre_id = genres.first.id
          section.save

          @pages = []
          genres.each do |g|
            @pages << create(:page, :with_section_news, name: 'index', genre_id: g.id)
          end
        end

        it "ページと同じ所属に属するジャンルのニュースコンテンツを含むページを返すこと" do
          expect(SectionNews.create_news_pages(@pages.first)).to eq(@pages)
        end
      end

      context "ページのパスが、設定されているカテゴリのトップページと一致する場合" do
        let!(:page) { create(:page, :with_section_news, name: 'bousai_news', genre_id: top_genre.id) }

        it "パスが一致すPageを返すこと" do
          expect(SectionNews.create_news_pages(page)).to eq([page])
        end
      end

      context "トップニュースのページの場合" do
        before do
          @page1 = create(:page, :with_section_news, name: 'top_news', genre_id: top_genre.id)
          @page2 = create(:page, :with_section_news, name: 'with_top', genre_id: top_genre.id)

          @except_pages = []

          Settings.section_news.top.except.each do |except_path|
            except_genre = create(:genre, name: except_path.gsub('/', ''), parent_id: top_genre.id)
            @except_pages << create(:page, :with_section_news, name: 'index', genre_id: except_genre.id)
          end
        end

        it "Settings.section_news.top.exceptで除外指定したパス以外の新着情報を返すこと" do
          expect(SectionNews.create_news_pages(@page1)).to eq([@page1, @page2])
        end

        it "Settings.section_news.top.exceptで除外指定したパスの新着情報を持つページを返さないこと" do
          expect(SectionNews.create_news_pages(@page1)).not_to include(@except_pages)
        end
      end

      context "その他のニュースページの場合" do
        before do
          @page1 = create(:page, :with_section_news, name: 'other_news', genre_id: top_genre.id)
          @page2 = create(:page, :with_section_news, name: 'other_news2', genre_id: top_genre.id)

          @except_pages = []

          Settings.section_news.other.except.each do |except_path|
            except_genre = create(:genre, name: except_path.gsub('/', ''), parent_id: top_genre.id)
            @except_pages << create(:page, :with_section_news, name: 'index', genre_id: except_genre.id)
          end
        end

        it "Settings.section_news.other.exceptで除外指定したパス以外の新着情報を返すこと" do
          expect(SectionNews.create_news_pages(@page1)).to eq([@page1, @page2])
        end

        it "Settings.section_news.other.exceptで除外指定したパスの新着情報を持つページを返さないこと" do
          expect(SectionNews.create_news_pages(@page1)).not_to include(@except_pages)
        end

      end

      context "それ以外の場合" do
        before do
          @genre1 = create(:genre, parent_id: top_genre.id)
          @genre1_pages1 = create_list(:page, 3, :with_section_news, genre_id: @genre1.id)
          @genre1_pages2 = create_list(:page, 3, genre_id: @genre1.id)

          @genre2 = create(:genre, parent_id: top_genre.id)
          @genre2_pages = create_list(:page, 3, :with_section_news, genre_id: @genre2.id)
        end

        it "同じフォルダ配下で新着情報を持つページを返すこと" do
          expect(SectionNews.create_news_pages(@genre1_pages1.first)).to eq(@genre1_pages1)
        end

        it "同じフォルダ配下で新着情報を持たないページを返さないこと" do
          expect(SectionNews.create_news_pages(@genre1_pages1.first)).not_to include(@genre1_pages2)
        end

        it "別のフォルダ配下で新着情報を持つページを返さないこと" do
          expect(SectionNews.create_news_pages(@genre1_pages1.first)).not_to include(@genre2_pages)
        end
      end
    end
  end
end
