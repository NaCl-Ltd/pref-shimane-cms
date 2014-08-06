require 'spec_helper'

describe Susanoo::PageView do
  let!(:top_genre) { create(:top_genre) }

  describe "#initialize" do
    context "pathが'/'の場合" do
      let(:path) { '/' }

      context "公開ページが無い場合" do
        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@dirに正しい値を設定していること" do
          expect(@page_view.dir).to eq('/')
        end

        it "@fileに正しい値を設定していること" do
          expect(@page_view.file).to eq('index')
        end

        it "@genreに正しい値を設定していること" do
          expect(@page_view.genre).to eq(top_genre)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page.attributes).to eq(Page.index_page(top_genre).attributes)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(nil)
        end

        it "@layoutにnormal_layoutが設定されていること" do
          expect(@page_view.layout).to eq(Susanoo::PageView::TOP_LAYOUT)
        end
      end

      context "公開ページがある場合" do
        let!(:page) { create(:page, :publish, name: 'index', genre_id: top_genre.id) }

        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page).to eq(page)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(page.publish_content)
        end

        it "@layoutにtop_layoutが設定されていること" do
          expect(@page_view.layout).to eq(Susanoo::PageView::TOP_LAYOUT)
        end
      end
    end

    context "pathが'/genre11/test.html'の場合" do
      let(:path) { '/genre11/test.html' }
      let!(:genre) { create(:genre, name: 'genre11', parent_id: top_genre.id) }

      context "公開ページがある場合" do
        let!(:page) { create(:page, :publish, name: 'test', genre_id: genre.id) }

        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@dirに正しい値を設定していること" do
          expect(@page_view.dir).to eq('/genre11')
        end

        it "@fileに正しい値を設定していること" do
          expect(@page_view.file).to eq(page.name)
        end

        it "@genreに正しい値を設定していること" do
          expect(@page_view.genre).to eq(genre)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page).to eq(page)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(page.publish_content)
        end

        it "@layoutにnormal_layoutが設定されていること" do
          expect(@page_view.layout).to eq(Susanoo::PageView::NORMAL_LAYOUT)
        end
      end
    end

    context "pathが'/genre11/test.html.i'の場合" do
      let(:path) { '/genre11/test.html.i' }
      let!(:genre) { create(:genre, name: 'genre11', parent_id: top_genre.id) }

      context "公開ページがある場合" do
        let!(:page) { create(:page, :publish, name: 'test', genre_id: genre.id) }

        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@dirに正しい値を設定していること" do
          expect(@page_view.dir).to eq('/genre11')
        end

        it "@fileに正しい値を設定していること" do
          expect(@page_view.file).to eq(page.name)
        end

        it "@genreに正しい値を設定していること" do
          expect(@page_view.genre).to eq(genre)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page).to eq(page)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(page.publish_content)
        end

        it "@layoutにnormal_layoutが設定されていること" do
          expect(@page_view.layout).to eq(Susanoo::PageView::NORMAL_LAYOUT)
        end

        it "@extensionに正しい値を設定していること" do
          expect(@page_view.instance_eval{ @extension }).to eq('.html.i')
        end
      end
    end

    context "pathが'/genre11'でGenreのトップ画面へアクセスがきた場合" do
      let(:path) { '/genre11' }
      let!(:genre) { create(:genre, name: 'genre11', parent_id: top_genre.id) }

      context "公開ページが無い場合" do
        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@dirに正しい値を設定していること" do
          expect(@page_view.dir).to eq('/genre11')
        end

        it "@fileに正しい値を設定していること" do
          expect(@page_view.file).to eq('index')
        end

        it "@genreに正しい値を設定していること" do
          expect(@page_view.genre).to eq(genre)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page.attributes).to eq(Page.index_page(genre).attributes)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(nil)
        end

        it "@layoutにgenre_top_layoutが設定されていること" do
          expect(@page_view.layout).to eq(Susanoo::PageView::GENRE_TOP_LAYOUT)
        end
      end

      context "公開ページがある場合" do
        let!(:page) { create(:page, :publish, name: 'index', genre_id: genre.id) }

        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page).to eq(page)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(page.publish_content)
        end

        it "@layoutにnormal_layoutが設定されていること" do
          expect(@page_view.layout).to eq(Susanoo::PageView::NORMAL_LAYOUT)
        end
      end
    end

    context "pathが'/genre11'でSectionのトップ画面へアクセスがきた場合" do
      let(:path) { '/genre11' }
      let!(:genre) { create(:section_top_genre, name: 'genre11', parent: top_genre) }

      context "公開ページがない場合" do
        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@dirに正しい値を設定していること" do
          expect(@page_view.dir).to eq('/genre11')
        end

        it "@fileに正しい値を設定していること" do
          expect(@page_view.file).to eq('index')
        end

        it "@genreに正しい値を設定していること" do
          expect(@page_view.genre).to eq(genre)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page.attributes).to eq(Page.index_page(genre).attributes)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(nil)
        end

        it "@layoutにgenre_top_layoutが設定されていること" do
          expect(@page_view.layout).to eq(Susanoo::PageView::SECTION_TOP_LAYOUT)
        end
      end

      context "公開ページがある場合" do
        let!(:page) { create(:page, :publish, name: 'index', genre_id: genre.id) }

        before do
          @page_view = Susanoo::PageView.new(path)
        end

        it "@pageに正しい値を設定していること" do
          expect(@page_view.page).to eq(page)
        end

        it "@publish_contentに正しい値を設定していること" do
          expect(@page_view.publish_content).to eq(page.publish_content)
        end
      end
    end

    context "page_contentが指定された場合" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page_publish, genre_id: top_genre.id) }

      before do
        @page_view = Susanoo::PageView.new(page_content: page.publish_content)
      end

      it "@publish_contentへ正しい値を設定していること" do
        expect(@page_view.publish_content).to eq(page.publish_content)
      end

      it "@pageへ正しい値を設定していること" do
        expect(@page_view.page).to eq(page)
      end

      it "@genreへ正しい値を設定していること" do
        expect(@page_view.genre).to eq(top_genre)
      end
    end
  end

  describe "#rendering_view_name" do
    let(:template) { 'show' }

    before do
      allow_any_instance_of(Susanoo::PageView).to receive(:template).and_return(template)
    end

    context "publish_contentが存在する場合" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page_publish, genre_id: top_genre.id) }

      before do
        @page_view = Susanoo::PageView.new(page.path)
      end

      it "決められたtemplateを返すこと" do
        expect(@page_view.rendering_view_name(false)).to eq(template)
      end
    end

    context "mobileの場合" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page_publish, genre_id: top_genre.id) }

      before do
        @page_view = Susanoo::PageView.new(page.path)
      end

      it "モバイル用のtemplateを返すこと" do
        expect(@page_view.rendering_view_name(true)).to eq('susanoo/visitors/mobiles/content')
      end
    end

    context "Pageが存在しない場合" do
      before do
        @page_view = Susanoo::PageView.new('/test/test/test.html')
      end

      it "not_foundを返すこと" do
        expect(@page_view.rendering_view_name(false)).to eq(
          action: 'not_found',
          status: 404,
          layout: false
        )
      end
    end
  end
end
