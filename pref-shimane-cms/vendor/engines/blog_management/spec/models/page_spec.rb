require 'spec_helper'

describe Genre do
  describe "スコープ" do
    describe "search" do
      let(:top) { create(:genre, parent_id: nil, path: "/") }

      # /genre1/2013/4と/genre1/2013/7までのジャンルが作成される
     let(:genre_1) do
        genre = create(:genre, parent_id: top.id, path: "/genre1/")
        genre.create_year_month_folder!(Date.new(2013, 4, 1))
        genre.create_year_month_folder!(Date.new(2013, 7, 1))
        genre
      end
      let(:genre_1_2013)   { genre_1.children.first }
      let(:genre_1_201304) { genre_1.children.first.children.where(:name => "4").first }
      let(:genre_1_201307) { genre_1.children.first.children.where(:name => "7").first }

      # /genre1/genre2/2013/4までのジャンルが作成される
      let(:genre_2) do
        genre = create(:genre, parent_id: genre_1.id, path: "/genre1/genre2/")
        genre.create_year_month_folder!(Date.new(2013, 4, 1))
        genre
      end
      let(:genre_2_201304) { genre_2.children.first.children.first }

      # /genre3/2014/8までのジャンルが作成される
      let(:genre_3) do
        genre = create(:genre, parent_id: top.id, path: "/genre3/")
        genre.create_year_month_folder!(Date.new(2014, 8, 1))
        genre
      end
      let(:genre_3_201408) { genre_3.children.first.children.first }

      context "キーワード検索の場合" do
        before do
          @page_editing  = create(:page_editing , genre: genre_1_201304, title: "ページいち", name: "1", blog_date: Date.new(2013, 4, 1))
          @page_request  = create(:page_request , genre: genre_1_201304, title: "ページに", name: "2", blog_date: Date.new(2013, 4, 1))
        end

        it "キーワードと部分一致するページタイトルを持つページを取得できること" do
          pages = Page.search_for_blog(genre_1_201304,  keyword: @page_editing.title)
          expect(pages).to eq([@page_editing])
        end

        it "キーワードと部分一致するページ名を持つページを取得できること" do
          pages = Page.search_for_blog(genre_1_201304,  keyword: @page_editing.name)
          expect(pages).to eq([@page_editing])
        end
      end

      context "ページの公開状態で検索する場合" do
        shared_examples_for "ページの公開状態で検索"do |label, admission, target|
          before do
            @page = {}
            name = 1
            date = Date.new(2013, 4, 1)
            FactoryGirl.with_options(genre: genre_1_201304) do |opt|
              %i(page_editing page_request page_reject page_publish page_cancel page_waiting page_finished).each_with_index do |sym, index|
                @page[sym]  = opt.create(sym, name: (index + 1).to_s, blog_date: date + 1)
              end
            end

            if target == :page_editing
              @target = [@page[:page_editing], @page[:page_publish],
                         @page[:page_cancel], @page[:page_waiting],
                         @page[:page_finished]]
            else
              @target = [@page[target]]
            end
          end

          it "#{label}のコンテンツが取得できること" do
            pages = Page.search_for_blog(genre_1_201304,  admission: admission).order("pages.id")
            expect(pages).to eq(@target)
          end
        end

        it_behaves_like("ページの公開状態で検索", "編集中", 0, :page_editing)
        it_behaves_like("ページの公開状態で検索", "公開依頼中", 1, :page_request)
        it_behaves_like("ページの公開状態で検索", "公開却下", 2, :page_reject)
        it_behaves_like("ページの公開状態で検索", "公開中", 3, :page_publish)
        it_behaves_like("ページの公開状態で検索", "公開停止", 4, :page_cancel)
        it_behaves_like("ページの公開状態で検索", "公開待ち", 5, :page_waiting)
        it_behaves_like("ページの公開状態で検索", "公開期限切れ", 6, :page_finished)
      end

      context "ブログの日付で検索する場合" do
        # ブログページは、月単位でフォルダに格納されているため、年月の開始終了の範囲検索
        # テストを行う場合は、年フォルダのサブフォルダを検索対象にしないと意味がない。
        # テストのcontextからは外れるが、ここではサブフォルダの検索を有効にする

        before do
          # NOTE: indexページを作っておかないとテストに落ちる
          create(:page, genre: genre_1, name: "index")
          create(:page, genre: genre_1_2013, name: "index")
          create(:page, genre: genre_1_201304, name: "index")
          create(:page, genre: genre_1_201307, name: "index")

          @page_1 = create(:page, genre: genre_1_201304, name: "1", blog_date: Date.new(2013, 4, 1))
          @page_content_1 = create(:page_content, page: @page_1)
          @page_2 = create(:page, genre: genre_1_201307, name: "1", blog_date: Date.new(2013, 7, 1))
          @page_content_2 = create(:page_content, page: @page_2)
        end

        it "指定した年月以降のブログページが取得できること" do
          pages = Page.search_for_blog(genre_1,  start_at: Date.new(2013,4,1), recursive: "1")
          expect(pages).to eq([@page_1, @page_2])
        end

        it "指定した年月以前のブログページが取得できること" do
          pages = Page.search_for_blog(genre_1,  end_at: Date.new(2013,7,1), recursive: "1")
          expect(pages).to eq([@page_1, @page_2])
        end

        it "指定した年月内のブログページが取得できること" do
          pages = Page.search_for_blog(genre_1.children.first,  start_at: Date.new(2013,4,1), end_at: Date.new(2013,6,1), recursive: "1")
          expect(pages).to eq([@page_1])
        end
      end

      context "サブフォルダを検索する場合" do
        before do
          @page_1 = create(:page_publish , genre: genre_1_201304, :name => "1", blog_date: Date.new(2013, 4, 1))
          @page_2 = create(:page_publish , genre: genre_2_201304, :name => "1", blog_date: Date.new(2013, 4, 1))
          @page_3 = create(:page_publish , genre: genre_3_201408, :name => "1", blog_date: Date.new(2014, 8, 1))
        end

        it "サブフォルダのページコンテンツが取得できること" do
          pages = Page.search_for_blog(genre_1,  recursive: "1")
          expect(pages).to eq([@page_1, @page_2])
        end
      end
    end
  end

  describe "メソッド" do
    describe "#blog_top_folder" do
      before do
        @top_blog_folder = create(:top_genre)
        @top_blog_folder.create_year_month_folder!
        year_blog_folder = @top_blog_folder.children.first
        @month_blog_folder = year_blog_folder.children.first
      end

      subject do
        create(:page_editing, genre_id: @month_blog_folder.id, name: "1").blog_top_folder
      end

      it "ブログトップフォルダが返されること" do
        expect(subject).to eq(@top_blog_folder)
      end
    end
  end
end
