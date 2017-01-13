require 'spec_helper'

describe Page do
  describe "バリデーション" do
    it { should validate_presence_of :genre_id }
    it { should validate_presence_of :name }
    it { should validate_presence_of :title }
    it { should validate_uniqueness_of(:name).scoped_to(:genre_id)  }
    it { should validate_uniqueness_of(:title).scoped_to(:genre_id)  }

    describe 'validate_format_of' do
      subject { create(:page) }
      it { should allow_value("abcde-01_23").for(:name) }
      it { should_not allow_value("/name").for(:name) }
    end

    describe 'validate_title' do
      it "機種依存文字が指定できないこと" do
        page = create(:page)
        page.title = 'タイトル①'
        page.valid?
        expect(page.errors[:title].any?).to be_true
      end
    end

    describe 'validate_length_of_title' do
      let(:section) { create(:section_base) }
      let(:genre)   { create(:genre, section: section) }

      before do
        @page = build(:page, genre: genre)
        @page.title = "あ" * 36
      end

      context "フォルダが指定されていない場合" do
        it "タイトルにエラーが発生しないこと" do
          @page.genre_id = nil
          @page.valid?
          expect(@page.errors[:title].any?).to be_false
        end
      end

      context "フォルダが指定されている場合" do
        context "フォルダの所属がsusanooを使用していない場合" do
          it "タイトルにエラーが発生しないこと" do
            @page.genre.section.stub(:susanoo?).and_return(false)
            @page.valid?
            expect(@page.errors[:title].any?).to be_false
          end
        end

        context "フォルダの所属がsusanooを使用している場合" do
          it "タイトルにエラーが発生すること" do
            @page.genre.section.stub(:susanoo?).and_return(true)
            @page.valid?
            expect(@page.errors[:title].any?).to be_true
          end
        end

        context "susanoo?自体存在しない場合" do
          it "タイトルにエラーが発生しないこと" do
            @page.genre.section.stub(:respond_to?).with(:susanoo?).and_return(false)
            @page.valid?
            expect(@page.errors[:title].any?).to be_true
          end
        end
      end
    end

    describe 'only_index_valid' do
      context "作成時の場合" do
        before do
          @genre1 = create(:genre).reload
          @genre2 = create(:genre, parent: @genre1).reload
          @genre3 = create(:genre).reload
        end

        context "所属トップフォルダ直下の場合" do
          before do
            @genre1.section.genre = @genre1
            @genre1.section.save!
          end

          it "index以外のページが作成できないこと" do
            page = build(:page, genre_id: @genre1.id, name: 'test')
            page.valid?
            expect(page.errors[:name].any?).to be_true
          end

          it "indexのページが作成できること" do
            page = build(:page, genre_id: @genre1.id, name: 'index')
            page.valid?
            expect(page.errors[:name].any?).to be_false
          end
        end

        context "所属トップフォルダ配下のフォルダの場合" do
          before do
            @genre1.section.genre = @genre1
            @genre1.section.save!
          end

          it "index以外のページが作成できないこと" do
            page = build(:page, genre_id: @genre2.id, name: 'test')
            page.valid?
            expect(page.errors[:name].any?).to be_true
          end

          it "indexのページが作成できること" do
            page = build(:page, genre_id: @genre2.id, name: 'index')
            page.valid?
            expect(page.errors[:name].any?).to be_false
          end
        end

        context "所属フォルダ以外のフォルダの場合" do
          before do
            @genre1.section.genre = @genre1
            @genre1.section.save!
          end

          it "index以外のページも作成できること" do
            page = build(:page, genre_id: @genre3.id, name: 'test')
            page.valid?
            expect(page.errors[:name].any?).to be_false
          end
        end

        context "フォルダと紐づいていない場合" do
          it "バリデートを通ること" do
            page = build(:page)
            page.name = 'test'
            genre = page.genre
            create(:section, top_genre_id: genre.id)
            page.genre = nil
            page.valid?

            expect(page.errors[:name].any?).to be_false
          end
        end
      end

      context "更新の場合" do
        it "バリデートを通ること" do
          page = create(:page)
          genre = page.genre
          create(:section, top_genre_id: genre.id)
          page.update(name: 'test')

          expect(page.errors[:name].any?).to be_false
        end
      end
    end
  end

  describe "スコープ" do
    describe "search" do
      before do
        # 日時を固定
        Timecop.freeze(Time.new(2013,4,1))
        @section_1 = create(:section)
        @top       = create(:genre, parent_id: nil, path: "/", section_id: @section_1.id)
        @genre_1   = create(:genre, parent_id: @top.id, path: "/genre1/", section_id: @section_1.id)
        @genre_2   = create(:genre, parent_id: @genre_1.id, path: "/genre1/genre2", section_id: @section_1.id)
        @genre_3   = create(:genre, parent_id: @top.id, path: "/genre3/", section_id: @section_1.id)
      end

      after do
        Timecop.return
      end

      context "キーワード検索の場合" do
        before do
          @page_editing  = create(:page_editing , genre: @genre_1, title: "page1", name: "page1")
          @page_request  = create(:page_request , genre: @genre_1, title: "page2", name: "page2")
        end

        it "キーワードと部分一致するページタイトルを持つページを取得できること" do
          pages = Page.search(@genre_1,  keyword: @page_editing.title)
          expect(pages).to eq([@page_editing])
        end

        it "キーワードと部分一致するページ名を持つページを取得できること" do
          pages = Page.search(@genre_1,  keyword: @page_editing.name)
          expect(pages).to eq([@page_editing])
        end
      end

      context "ページの公開状態で検索する場合" do
        shared_examples_for "ページの公開状態で検索"do |label, admission, target|
          before do
            @page = {}
            @page[:page_editing]  = create(:page_editing , genre: @genre_1)
            @page[:page_request]  = create(:page_request , genre: @genre_1)
            @page[:page_reject]   = create(:page_reject  , genre: @genre_1)
            @page[:page_publish]  = create(:page_publish , genre: @genre_1)
            @page[:page_cancel]   = create(:page_cancel  , genre: @genre_1)
            @page[:page_waiting]  = create(:page_waiting , genre: @genre_1)
            @page[:page_finished] = create(:page_finished, genre: @genre_1)

            if target == :page_editing
              @target = [@page[:page_editing], @page[:page_publish],
                         @page[:page_cancel] , @page[:page_waiting],
                         @page[:page_finished]]
            else
              @target = [@page[target]]
            end
          end

          it "#{label}のコンテンツが取得できること" do
            pages = Page.search(@genre_1, admission: admission).order("pages.id")
            expect(pages.to_a).to eq(@target)
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

      context "更新日時で検索する場合" do
        before do
          @page_1 = create(:page , genre: @genre_1)
          @page_2 = create(:page , genre: @genre_1)
          @page_content_1 = create(:page_content, page: @page_1, last_modified: Date.new(2013,4,1))
          @page_content_1 = create(:page_content, page: @page_1, last_modified: Date.new(2013,5,1))
        end

        it "指定した日時以降に更新したコンテンツが取得できること" do
          pages = Page.search(@genre_1,  start_at: Date.new(2013,4,1))
          expect(pages).to eq([@page_1])
        end

        it "指定した日時以前に更新したコンテンツが取得できること" do
          pages = Page.search(@genre_1,  end_at: Date.new(2013,4,30))
          expect(pages).to eq([@page_1])
        end

        it "指定した範囲に更新したコンテンツが取得できること" do
          pages = Page.search(@genre_1,  start_at: Date.new(2013,4,1), end_at: Date.new(2013,4,30))
          expect(pages).to eq([@page_1])
        end
      end

      context "サブフォルダを検索する場合" do
        before do
          @page_1 = create(:page_publish , genre: @genre_1)
          @page_2 = create(:page_publish , genre: @genre_2)
          @page_3 = create(:page_publish , genre: @genre_3)
        end

        it "サブフォルダのページコンテンツが取得できること" do
          pages = Page.search(@genre_1,  recursive: "1").order('pages.id')
          expect(pages).to eq([@page_1, @page_2])
        end
      end

      context "コピーしたページがある場合" do
        context "キーワードで検索する場合" do
          before do
            @page_editing  = create(:page_editing , genre: @genre_1, title: "page1", name: "page1")
            @page_request  = create(:page_request , genre: @genre_1, title: "page2", name: "page2")
            @page_editing_copy = create(:page , genre: @genre_2,
              original_id: @page_editing.id, title: "page1_copy", name: "page1_copy")
            @page_request_copy = create(:page , genre: @genre_2,
              original_id: @page_request.id, title: "page2_copy", name: "page2_copy")
          end

          it "キーワードと部分一致するページタイトルを持つページを取得できること" do
            pages = Page.search(@genre_2,  keyword: @page_editing_copy.title, include_copy: "1")
            expect(pages).to eq([@page_editing_copy])
          end

          it "キーワードと部分一致するページ名を持つページを取得できること" do
            pages = Page.search(@genre_2,  keyword: @page_editing_copy.name, include_copy: "1")
            expect(pages).to eq([@page_editing_copy])
          end
        end

        context "ページの公開状態で検索する場合" do
          shared_examples_for "ページの公開状態で検索"do |label, admission, target|
            before do
              @page = {}
              @page[:page_editing]  = create(:page_editing , genre: @genre_1)
              @page[:page_request]  = create(:page_request , genre: @genre_1)
              @page[:page_reject]   = create(:page_reject  , genre: @genre_1)
              @page[:page_publish]  = create(:page_publish , genre: @genre_1)
              @page[:page_cancel]   = create(:page_cancel  , genre: @genre_1)
              @page[:page_waiting]  = create(:page_waiting , genre: @genre_1)
              @page[:page_finished] = create(:page_finished, genre: @genre_1)

              @copy_page = {}
              @page.each do |key, page|
                @copy_page[key] = create(:page, original_id: page.id, genre: @genre_2)
              end
              if target == :page_editing
                @target = [@copy_page[:page_editing], @copy_page[:page_publish],
                           @copy_page[:page_cancel] , @copy_page[:page_waiting],
                           @copy_page[:page_finished]]
              else
                @target = [@copy_page[target]]
              end
            end

            it "#{label}のコンテンツが取得できること" do
              pages = Page.search(@genre_2, admission: admission, include_copy: "1").order("pages.id")
              expect(pages.to_a).to eq(@target)
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
      end


      context "ユーザを指定する場合" do
        before do
          @page_1 = create(:page_publish , genre: @genre_1)
          @page_2 = create(:page_publish , genre: @genre_2)
          @page_3 = create(:page_publish , genre: @genre_3)

          @section_2 = create(:section)
          @user = create(:normal_user, section_id: @section_2.id)

          @genre_4 = create(:genre, section_id: @section_2.id, parent_id: @genre_1.id)
          @genre_5 = create(:genre, section_id: @section_2.id, parent_id: @genre_2.id)
          @genre_6 = create(:genre, section_id: @section_2.id, parent_id: @genre_3.id)
          @page_4 = create(:page_publish , genre: @genre_4)
          @page_5 = create(:page_publish , genre: @genre_5)
          @page_6 = create(:page_publish , genre: @genre_6)
        end

        context "管理者の場合" do
          it "全ページが取得できること" do
            pages = Page.search(@top,  {recursive: "1"}, {user: @admin}).order('pages.id')
            expect(pages).to eq([@page_1, @page_2, @page_3, @page_4, @page_5, @page_6])
          end
        end

        context "管理者以外の場合" do
          it "ユーザが所有権を持つ全ページが取得できること" do
            pages = Page.search(@top,  {recursive: "1"}, {user: @user}).order('pages.id')
            expect(pages).to eq([@page_4, @page_5, @page_6])
          end
        end
      end
    end
  end

  describe "メソッド" do
    describe "#url" do
      before do
        @top = create(:top_genre, section_id: 1)
        @child = create(:genre, parent_id: @top.id, section_id: 10, no: 1)
        @page = create(:page, genre_id: @child.id)
      end

      it "base_uriの末尾が重複しないこと" do
        Settings.stub(:base_uri) { "http://localhost:3000/" }
        expect(@page.url).to eq "http://localhost:3000/#{@child.name}/#{@page.name}.html"
      end
    end

    describe "#latest_content" do
      let(:page_publish) {create(:page_publish)}
      let(:page_editing) {create(:page_editing)}

      context "original_id が nil の場合" do
        it "最新の公開コンテンツが取得できること" do
          expect(page_publish.latest_content).to eq page_publish.contents.where(latest: true).first
        end

        it "公開コンテンツを持たない場合nilが返ること" do
          expect(page_editing.latest_content).to be_nil
        end
      end

      context "original_id が nil でない場合" do
        let(:page_publish_copy) {create(:page, original_id: page_publish.id)}
        let(:page_editing_copy) {create(:page, original_id: page_editing.id)}

        it "コピー元の最新の公開コンテンツが取得できること" do
          expect(page_publish_copy.latest_content).to eq page_publish.contents.where(latest: true).first
        end

        it "コピー元が公開コンテンツを持たない場合 nil が返ること" do
          expect(page_editing_copy.latest_content).to be_nil
        end
      end
    end

    describe "#private_content" do
      let(:page_publish) { create(:page_publish) }
      let(:page_publish_without_private) { create(:page_publish_without_private) }

      context "original_id が nil の場合" do
        it "編集中コンテンツを取得できること" do
          expect(page_publish.private_content).to eq page_publish.contents.first
        end

        it "編集中コンテンツを持たない場合 nil が返ること" do
          expect(page_publish_without_private.private_content).to be_nil
        end
      end

      context "original_id が nil でない場合" do
        let(:page_publish_copy) {create(:page, original_id: page_publish.id)}
        let(:page_publish_without_private_copy) {create(:page, original_id: page_publish_without_private.id)}

        it "コピー元の編集中コンテンツを取得できること" do
          expect(page_publish_copy.private_content).to eq page_publish.contents.first
        end

        it "コピー元が編集中コンテンツを持たない場合 nil が返ること" do
          expect(page_publish_without_private_copy.private_content).to be_nil
        end
      end

    end

    describe "#publish_content" do
      let(:page) { create(:page) }
      let(:page_finished) { create(:page_finished) }

      it "公開中のコンテンツが複数ある場合、最新のコンテンツが返ること" do
        page_content_publish_1 = create(:page_content_publish, page_id: page.id, latest: false)
        page_content_publish_2 = create(:page_content_publish, page_id: page.id, latest: true)
        expect(page.publish_content).to eq(page_content_publish_2)
      end

      it "最新のコンテンツが公開停止の場合、nilが返ること" do
        page_content_publish = create(:page_content_publish, page_id: page.id, latest: false)
        page_content_cancel  = create(:page_content_cancel , page_id: page.id, latest: true)
        expect(page.publish_content).to be_nil
      end

      it "最新のコンテンツが公開待ちで、1つ前の履歴が公開中の場合、１つ前の履歴が返ること" do
        page_content_publish = create(:page_content_publish, page_id: page.id, latest: false)
        page_content_waiting = create(:page_content_waiting, page_id: page.id, latest: true)
        expect(page.publish_content).to eq(page_content_publish)
      end

      it "最新のコンテンツが公開期限切れの場合、nilが返ること" do
        page_content_publish  = create(:page_content_publish , page_id: page.id, latest: false)
        page_content_finished = create(:page_content_finished, page_id: page.id, latest: true)
        expect(page.publish_content).to be_nil
      end

      it "最新のコンテンツが公開待ちで、1つ前の履歴が公開停止の場合、nilが返ること" do
        page_content_cancel  = create(:page_content_cancel , page_id: page.id, latest: false)
        page_content_waiting = create(:page_content_waiting, page_id: page.id, latest: true)
        expect(page.publish_content).to be_nil
      end

      it "最新のコンテンツが公開待ちで、1つ前の履歴が公開期限切れの場合、nilが返ること" do
        page_content_finished = create(:page_content_finished, page_id: page.id, latest: false)
        page_content_waiting  = create(:page_content_waiting , page_id: page.id, latest: true)
        expect(page.publish_content).to be_nil
      end

      context "original_id が nil の場合" do
        before do
          @page_content_publish = create(:page_content_publish, page_id: page.id)
          @page_content_waiting = create(:page_content_waiting, page_id: page.id)
        end

        it "公開中コンテンツを取得できること" do
          expect(page.publish_content).to eq @page_content_publish
        end

        it "公開中コンテンツを持たない場合, nil が返ること" do
          expect(page_finished.publish_content).to be_nil
        end
      end

      context "original_id が nil でない場合" do
        let(:page_copy) {create(:page, original_id: page.id)}
        let(:page_finished_copy) {create(:page, original_id: page_finished.id)}

        before do
          @page_content_publish = create(:page_content_publish, page_id: page.id)
          @page_content_waiting = create(:page_content_waiting, page_id: page.id)
        end

        it "コピー元の公開中コンテンツを取得できること" do
          expect(page_copy.publish_content).to eq @page_content_publish
        end

        it "公開中コンテンツを持たない場合, nil が返ること" do
          expect(page_finished_copy.publish_content).to be_nil
        end
      end
    end

    describe "#published_content" do
      let(:page_publish) { create(:page_publish) }
      let(:page_waiting) { create(:page_waiting) }

      context "original_id が nil の場合" do
        it "公開済みコンテンツを取得できること" do
          expect(page_publish.published_content).to eq page_publish.contents.last
        end

        it "公開済みコンテンツを持たない場合nilが返ること" do
          expect(page_waiting.published_content).to be_nil
        end
      end

      context "original_id が nil でない場合" do
        let(:page_publish_copy) {create(:page, original_id: page_publish.id)}
        let(:page_waiting_copy) {create(:page, original_id: page_waiting.id)}

        it "コピー元の公開済みコンテンツを取得できること" do
          expect(page_publish_copy.published_content).to eq page_publish.contents.last
        end

        it "コピー元が公開済みコンテンツを持たない場合nilが返ること" do
          expect(page_waiting_copy.published_content).to be_nil
        end
      end

    end

    describe "#unpublished_content" do
      let(:page_publish) { create(:page_publish) }
      let(:page_waiting_without_private) { create(:page_waiting_without_private) }

      context "original_id が nil の場合" do
        it "編集中・公開待ちコンテンツ両方を持つ場合、編集中コンテンツを取得できること" do
          expect(page_publish.unpublished_content).to eq page_publish.contents.first
        end

        it "公開待ちコンテンツを取得できること" do
          expect(page_waiting_without_private.unpublished_content).to eq page_waiting_without_private.contents.last
        end
      end

      context "original_id が nil でない場合" do
        let(:page_publish_copy) {create(:page, original_id: page_publish.id)}
        let(:page_waiting_without_private_copy) {create(:page, original_id: page_waiting_without_private.id)}

        it "コピー元の編集中・公開待ちコンテンツ両方を持つ場合、編集中コンテンツを取得できること" do
          expect(page_publish_copy.unpublished_content).to eq page_publish.contents.first
        end

        it "コピー元の公開待ちコンテンツを取得できること" do
          expect(page_waiting_without_private_copy.unpublished_content).to eq page_waiting_without_private.contents.last
        end
      end
    end

    describe "#waiting_content" do
      let(:page_waiting) { create(:page_waiting) }
      let(:page_publish) { create(:page_publish) }

      context "original_id が nil の場合" do
        it "公開待ちコンテンツを取得できること" do
          expect(page_waiting.waiting_content).to eq page_waiting.contents.last
        end

        it "公開待ちコンテンツを持たない場合、nilが返ること" do
          expect(page_publish.waiting_content).to be_nil
        end
      end

      context "original_id が nil でない場合" do
        let(:page_waiting_copy) {create(:page, original_id: page_waiting.id)}
        let(:page_publish_copy) {create(:page, original_id: page_publish.id)}

        it "コピー元の公開待ちコンテンツを取得できること" do
          expect(page_waiting_copy.waiting_content).to eq page_waiting.contents.last
        end

        it "コピー元が公開待ちコンテンツを持たない場合、nilが返ること" do
          expect(page_publish_copy.waiting_content).to be_nil
        end
      end
    end

    describe "#editing_content" do
      let(:page_publish) {create(:page_publish)}
      let(:page_publish_without_private) {create(:page_publish_without_private)}

      context "original_id が nil の場合" do
        it "編集中コンテンツを取得できること" do
          expect(page_publish.editing_content).to eq page_publish.contents.first
        end

        it "編集中コンテンツを持たない場合、nilが返ること" do
          expect(page_publish_without_private.editing_content).to be_nil
        end
      end

      context "original_id が nil でない場合" do
        let(:page_publish_copy) {create(:page, original_id: page_publish.id)}
        let(:page_publish_without_private_copy) {create(:page, original_id: page_publish_without_private.id)}

        it "コピー元の編集中コンテンツを取得できること" do
          expect(page_publish_copy.editing_content).to eq page_publish.contents.first
        end

        it "コピー元が編集中コンテンツを持たない場合、nilが返ること" do
          expect(page_publish_without_private_copy.editing_content).to be_nil
        end
      end
    end

    describe "#request_content" do
      let(:page_request) {create(:page_request)}
      let(:page_publish) {create(:page_publish)}

      context "original_id が nil の場合" do
        it "公開依頼中コンテンツを取得できること" do
          expect(page_request.request_content).to eq page_request.contents.last
        end

        it "公開依頼中コンテンツを持たない場合、nilが返ること" do
          expect(page_publish.request_content).to be_nil
        end
      end

      context "original_id が nil でない場合" do
        let(:page_request_copy) {create(:page, original_id: page_request.id)}
        let(:page_publish_copy) {create(:page, original_id: page_publish.id)}

        it "コピー元の公開依頼中コンテンツを取得できること" do
          expect(page_request_copy.request_content).to eq page_request.contents.last
        end

        it "コピー元が公開依頼中コンテンツを持たない場合、nilが返ること" do
          expect(page_publish_copy.request_content).to be_nil
        end
      end
    end

    describe "#deletable?" do
      let!(:user) { create(:user) }

      it "cancel_pageジョブを持つ場合, falseが返ること" do
        page = create(:page_editing)
        Job.create(action: Job::CANCEL_PAGE, arg1: page.id.to_s)
        expect(page.deletable?(user)).to be_false
      end

      it "公開中コンテンツを持つ場合, falseが返ること" do
        expect(create(:page_publish).deletable?(user)).to be_false
      end

      it "公開待ちコンテンツを持つ場合, falseが返ること" do
        expect(create(:page_waiting).deletable?(user)).to be_false
      end

      it "編集コンテンツのみ場合, trueが返ること" do
        expect(create(:page_editing).deletable?(create(:user))).to be_true
      end

      context "公開依頼中のコンテンツを持つ場合" do
        before { @page = create(:page_request) }

        it "ログインユーザが運用管理者の場合, trueが返ること" do
          expect(@page.deletable?(create(:user))).to be_true
        end

        it "ログインユーザが情報提供管理者の場合, trueが返ること" do
          expect(@page.deletable?(create(:section_user))).to be_true
        end

        it "ログインユーザがホームページ担当者の場合, falseが返ること" do
          expect(@page.deletable?(create(:normal_user))).to be_false
        end
      end
    end

    describe "#url_base_path" do
      it "パスが返ること" do
        page = create(:page)
        expect(page.url_base_path).to eq("#{page.genre.path}#{page.name}")
      end

      it "genreがnilの場合空文字が返ること" do
        page = create(:page)
        page.genre_id = nil
        expect(page.url_base_path).to eq ""
      end
    end

    describe "#url_path" do
      it "パスが返ること" do
        page = create(:page)
        expect(page.url_path).to eq("#{page.genre.path}#{page.name}.html")
      end

      it "ページ名がindexの場合、パスにページ名を含まないこと" do
        page = create(:page, name: "index")
        expect(page.url_path).to eq("#{page.genre.path}")
      end

      it "genreがnilの場合空文字が返ること" do
        page = create(:page)
        page.genre_id = nil
        expect(page.url_path).to eq ""
      end
    end

    describe "#section" do
      subject{ page.section }

      let(:section) { create(:section) }
      let(:genre) { create(:genre, section_id: section.id) }
      let(:page) { create(:page, genre_id: genre.id) }

      it "self.genre.sectionが返ること" do
        expect(subject).to eq(section)
      end

      context 'genreがnilの場合' do
        it 'nil が返ること' do
          page.genre = nil
          expect(subject).to be_nil
        end
      end
    end

    describe "#template" do
      subject{ page.template }

      let(:section) { create(:section) }
      let(:genre) { create(:genre, section_id: section.id) }
      let(:page) { create(:page, genre_id: genre.id) }

      it "section.templateの値が返ること" do
        expect(subject).to eq(section.template)
      end
    end

    describe "#path_base" do
      subject{ page.path_base }

      let(:top_genre) { create(:top_genre) }
      let(:genre) { create(:genre, parent_id: top_genre.id) }
      let(:page) { create(:page, genre_id: genre.id) }

      it "GenreのパスとPageの名前を連結して返却していること" do
        expect(subject).to eq(genre.path + page.name)
      end
    end

    describe "#path" do
      subject{ page.path }

      context "Genreが無い場合" do
        let(:page) { stub_model(Page, genre: nil) }

        it "''が返ること" do
          expect(subject).to eq('')
        end
      end

      context "self.genreでGenreインスタンスが返る場合" do
        let(:top_genre) { create(:top_genre) }
        let(:genre) { create(:genre, parent_id: top_genre.id) }

        context "Pageのnameが'index'の場合" do
          let(:page) { create(:page, name: 'index', genre_id: genre.id) }

          it "Genreのpathを返すこと" do
            expect(subject).to eq(genre.path)
          end
        end

        context "Pageの名前が'index'以外の場合" do
          let(:page) { create(:page, genre_id: genre.id) }

          it "path_base + '.html'を返すこと" do
            expect(subject).to eq(page.path_base + ".html")
          end
        end
      end
    end

    describe "#news_title" do
      context "news_titleが設定されている場合" do
        let(:news_title) { 'news-title' }
        let(:page) { create(:page) }
        let!(:publish_content) { create(:page_content, :publish, page_id: page.id, news_title: news_title) }

        it "news_titleを返すこと" do
          expect(page.news_title).to eq(news_title)
        end
      end

      context "news_titleが設定されていない場合" do
        let(:title) { 'test-title' }
        let(:page) { create(:page, title: title) }
        let!(:publish_content) { create(:page_content, :publish, page_id: page.id) }

        it "pageのtitleを返すこと" do
          expect(page.news_title).to eq(title)
        end
      end
    end

    describe ".index_page" do
      let(:genre) { create(:genre) }

      it "新しくPageインスタンスを作成していること" do
        expect(Page.index_page(genre)).to be_a_new(Page)
      end
    end

    describe "#reflect_editing_content" do
      let(:user) { create(:user) }
      let(:page_content) { build(:page_content, :publish) }

      subject { page.reflect_editing_content(page_content, user) }

      context "公開待ちページを持つ場合" do
        let(:page) { create(:page_waiting) }

        it "falseが返ること" do
          expect(subject).to be_false
        end
      end

      context "公開依頼中ページを持つ場合" do
        let(:page) { create(:page_request) }

        context "ユーザがHP担当者以外の場合" do
          it "trueが返ること" do
            expect(subject).to be_true
          end
        end

        context "ユーザがHP担当者の場合" do
          let(:user) { create(:normal_user) }
          it "falseが返ること" do
            expect(subject).to be_false
          end
        end
      end

      context "コンテンツのフォーマットが古い場合" do
        let(:page) { create(:page) }
        let(:page_content) {
          create(:page_content, :publish, page_id: page.id, format_version: 0,
            content: '<h1>1</h1><p>2</p>',
            mobile: '<p>1</p>'
          )
        }

        it "フォーマットが変換されること" do
          subject
          page.reload
          expect(page.contents.first.content).to eq(%Q(<div class="#{PageContent.editable_class[:field]}">\n<h1>1</h1>\n<div>\n<p>2</p>\n</div>\n</div>))
          expect(page.contents.first.mobile).to eq(%Q(<div class="#{PageContent.editable_class[:field]}">\n<div>\n<p>1</p>\n</div>\n</div>))
        end
      end
    end

    describe "#move_to!" do
      let(:user) { create(:normal_user) }
      let(:top_genre) { create(:top_genre, section_id: user.section_id) }
      let(:to_genre) { create(:genre, section_id: user.section_id, parent: top_genre) }
      let(:genre) { create(:genre, section_id: user.section_id, parent: top_genre) }
      let(:page) { create(:page, genre: genre, name: 'page') }
      let(:other_page) { create(:page, genre: genre, name: 'other_page') }

      subject { page.move_to!(user, to_genre) }

      context "正常系" do
        it "ページのフォルダが移動先のフォルダに変更されること" do
          expect { subject }.to change { page.genre_id }.from(genre.id).to(to_genre.id)
        end

        it "フォルダ移動ジョブが追加されること" do
          old_path = page.path
          expect { subject }.to change(Job, :count).by(1)
          new_job = Job.last
          expect_job = Job.new(action: Job::MOVE_PAGE, arg1: to_genre.path, arg2: old_path.to_s, datetime: Time.now, queue: Job.queues[:move_export])
          expect(new_job.attributes.except('id', 'datetime')).to eq(expect_job.attributes.except('id', 'datetime'))
        end

        context "ページへのリンクを持つPageContentが存在する場合" do
          context "公開コンテンツがある場合" do
            before do
              @page_content = create(:page_content_publish, page: other_page, content: %Q(<a href="#{page.path}">link</a>))
              @page_links = []
              @page_links << create(:page_link, page_content_id: @page_content.id, link: page.path)
              @page_links << create(:page_link, page_content_id: @page_content.id, link: page.path_base+'.data/a.txt')
            end

            it "コンテンツの内容が変更されること" do
              subject
              expect(@page_content.reload.content).to eq(%Q(<a href="#{to_genre.path + page.name + '.html'}">link</a>))
            end

            it "ページリンクの作成されること" do
              subject
              @page_content.reload.links.each do |l|
                expect(l.reload.link =~ %r!#{to_genre.path + page.name}!).to be_true
              end
            end

            it "create_pageジョブが追加されること" do
              expect_job = Job.new(action: Job::CREATE_PAGE, arg1: other_page.id.to_s, datetime: Time.now, queue: Job.queues[:move_export])
              expect { subject }.to change(Job, :count).by(1+1)
              new_job = Job.where(arg1: other_page.id.to_s).first
              expect(new_job.attributes.except('id', 'datetime')).to eq(expect_job.attributes.except('id', 'datetime'))
            end
          end
          context "公開コンテンツがない場合" do
            before do
              @page_content = create(:page_content_editing, page: other_page, content: %Q(<a href="#{page.path}">link</a>))
              @page_links = []
              @page_links << create(:page_link, page_content_id: @page_content.id, link: page.path)
            end

            it "create_pageジョブが追加されないこと" do
              expect { subject }.to change(Job, :count).by(1)
              new_job = Job.where(arg1: other_page.id.to_s).first
              expect(new_job.blank?).to be_true
            end

          end
        end
      end

      context "異常系" do
        context "公開待ちページと公開中ページを持つ場合" do
          before do
            create(:page_content_publish, page: page)
            create(:page_content_waiting, page: page)
          end

          it "falseが返ること" do
            expect(subject).to be_false
            expect(page.errors[:base]).to eq([I18n.t('activerecord.errors.models.page.cannot_move')])
          end
        end

        context "ページのアクセス権限を持たない場合" do
          before do
            genre.section_id += 1
          end

          it "falseが返ること" do
            expect(subject).to be_false
            expect(page.errors[:base]).to eq([I18n.t('activerecord.errors.models.page.no_page_permission')])
          end
        end

        context "移動先のフォルダの権限を持たない場合" do
          before do
            to_genre.section_id += 1
          end

          it "falseが返ること" do
            expect(subject).to be_false
            expect(page.errors[:base]).to eq([I18n.t('activerecord.errors.models.page.no_genre_permission')])
          end
        end

        context "移動元と移動先のフォルダが同じ場合" do
          before do
            to_genre.id = genre.id
          end

          it "falseが返ること" do
            expect(subject).to be_false
            expect(page.errors[:base]).to eq([I18n.t('activerecord.errors.models.page.not_move')])
          end
        end
      end
    end

    describe "#original_contents" do
      let(:page) { create(:page_publish) }
      let(:copy_page) { create(:page, original_id: page.id) }

      it "original_idが存在する場合コピー元のコンテンツが取得できること" do
        expect(copy_page.original_contents.to_a).to eq(page.contents.to_a)
      end
    end

    describe "#remove_attachment_dir" do
      let!(:page) { create(:page) }
      let(:attachment_root) { Rails.root.join('files', Rails.env) }
      let(:attachment_dir)  { attachment_root.join(page.id.to_s) }
      let(:other_attachment_dir)  { attachment_root.join('0') }

      context '添付ファイルが存在する場合' do
        before do
          FileUtils.mkdir_p attachment_dir
          FileUtils.touch attachment_dir.join('test.txt')
          FileUtils.mkdir_p other_attachment_dir
        end

        after do
          FileUtils.rm_rf attachment_dir
          FileUtils.rm_rf other_attachment_dir
        end

        it '例外は発生しないこと' do
          expect { page.remove_attachment_dir }.to_not raise_error
        end

        it 'ディレクトリごと削除すること' do
          page.remove_attachment_dir
          expect(attachment_dir).to_not exist
        end

        it '他のページのディレクトリは削除しないこと' do
          page.remove_attachment_dir
          expect(other_attachment_dir).to exist
        end
      end

      context '添付ファイルが存在しない場合' do
        before do
          FileUtils.rm_rf attachment_dir
          FileUtils.mkdir_p other_attachment_dir
        end

        after do
          FileUtils.rm_rf attachment_dir
          FileUtils.rm_rf other_attachment_dir
        end

        it '例外は発生しないこと' do
          expect { page.remove_attachment_dir }.to_not raise_error
        end

        it 'ディレクトリは存在しないこと' do
          page.remove_attachment_dir
          expect(attachment_dir).to_not exist
        end

        it '他のページのディレクトリは削除しないこと' do
          page.remove_attachment_dir
          expect(other_attachment_dir).to exist
        end
      end
    end

    describe "#clear_duplication_latest" do
      subject{ page.clear_duplication_latest }

      describe '正常系' do
        let(:page) {create(:page_publish_with_waiting)}

        it '(前提) latest: true のコンテンツが2つあること' do
          expect(page.contents.where(latest: true).count).to eq 2
        end

        context 'ページが公開中で公開待ちコンテンツがある場合' do
          it 'latest: true のコンテンツが2つのままであること' do
            subject
            expect(page.contents.where(latest: true).count).to eq 2
          end
        end

        context 'ページが公開中で公開待ちコンテンツが公開中になった場合' do
          let!(:waiting_one){ page.contents.eq_waiting.first }
          let!(:publish_one){ page.contents.eq_published.first }

          before do
            waiting_one.update_columns(begin_date: Time.now - 1.days)
          end

          it '公開待ちだったコンテンツが latest: true であること' do
            subject 
            expect(waiting_one.reload.latest).to eq true
          end

          it '以前公開中だったコンテンツ latest: false であること' do
            subject 
            expect(publish_one.reload.latest).to eq false
          end
        end
      end

      describe '異常系' do
        let(:page) {create(:page_editing)}

        it '処理対象ではないページでも処理が問題なく終了すること' do
          expect(subject).to eq nil
        end
      end
    end
  end
end
