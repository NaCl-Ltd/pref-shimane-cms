require 'spec_helper'

describe Susanoo::PagesController do
  let(:valid_attributes) { {  } }

  let(:valid_session) { {} }

  describe "フィルタ" do
    describe "lonin_required" do
      shared_examples_for "未ログイン時のアクセス制限" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、ログイン画面が表示されること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end
      end

      shared_examples_for "ログイン時のアクセス制限"  do |met, act|
        before{@user = login(create(:user))}
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      controller do
        %w(index new create edit update destroy select).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        controller.stub(:set_susanoo_page).and_return(true)
        @routes.draw do
          resources :anonymous do
            collection do
              get :select
            end
          end
        end
        @page = create(:page)
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index) {before{get :index}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :new) {before{get :new}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create) {before{post :create}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :edit) {before{get :edit, id: @page.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update) {before{patch :update, id: @page.id}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy, id: @page.id}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :select) {before{get :select}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :index) {before{get :index}}
        it_behaves_like("ログイン時のアクセス制限", :get, :new) {before{get :new}}
        it_behaves_like("ログイン時のアクセス制限", :post, :create) {before{post :create}}
        it_behaves_like("ログイン時のアクセス制限", :get, :edit) {before{get :edit, id: @page.id}}
        it_behaves_like("ログイン時のアクセス制限", :patch, :update) {before{patch :update, id: @page.id}}
        it_behaves_like("ログイン時のアクセス制限", :delete, :destroy){before{delete :destroy, id: @page.id}}
        it_behaves_like("ログイン時のアクセス制限", :post, :select) {before{get :select}}
      end
    end
  end

  describe "アクション" do
    before do
      @section_1 = create(:section_base)
      @section_2 = create(:section_base)
      @genre_1 = create(:genre, path: "/", section_id: @section_1.id)
      @genre_2 = create(:genre, parent_id: @genre_1.id, path: "/genre2", section_id: @section_1.id)
      @genre_3 = create(:genre, parent_id: @genre_1.id, path: "/genre3", section_id: @section_2.id)
    end

    describe "GET index" do
      before do
        login create(:normal_user, section_id: @section_1.id)

        @page = {}
        [@genre_1, @genre_2, @genre_3].each do |genre|
          @page[genre] = [
            create(:page_publish, genre: genre),
            create(:page_editing, genre: genre)
          ]
        end
      end

      describe "正常系" do
        subject { get :index }

        it "テンプレートindexを表示できること" do
          expect(subject).to render_template('index')
        end

        it "genreオブジェクトが取得できていること" do
          subject
          expect(assigns[:genre]).to eq(@genre_1)
        end

        it "pagesオブジェクトが取得できていること" do
          subject
          expect(assigns[:pages]).to eq(@page[@genre_1])
        end

        it "検索条件に一致したページコンテンツが取得できること" do
          get :index, search: {admission: 3}
          expect(assigns[:pages]).to eq([@page[@genre_1][0]])
        end

      end
    end

    describe "GET select" do
      before do
        login create(:normal_user, section_id: @section_1.id)

        @page = {}
        [@genre_1, @genre_2].each do |genre|
          @page[genre] = [create(:page_publish, genre: genre)]
        end
      end

      describe "正常系" do
        subject { get :select, genre_id: @genre_1.id, format: 'js'}

        it "テンプレートselectを表示できること" do
          expect(subject).to render_template('select')
        end

        it "genreオブジェクトが取得できていること" do
          subject
          expect(assigns[:genre]).to eq(@genre_1)
        end

        it "pagesオブジェクトが取得できていること" do
          subject
          expect(assigns[:pages]).to eq(@page[@genre_1])
        end
      end

      describe "異常系" do
        context "フォルダを指定しない場合" do
          it "レスポンスが404であること" do
            get :select, format: 'js'
            expect(response.status).to eq 404
          end
        end

        context "別所属のフォルダにアクセスした場合" do
          it "レスポンスが404であること" do
            get :select, genre_id: @genre_3.id, format: 'js'
            expect(response.status).to eq 404
          end
        end
      end

    end

    describe "GET show" do
      before do
        login create(:user, section_id: @section_1.id)
      end

      describe "正常系" do
        it "テンプレートshowを表示できること" do
          page = create(:page_publish, genre: @genre_1)
          get :show, id: page.id
          expect(response).to render_template('show')
        end

        it "pageオブジェクトが取得できていること" do
          page = create(:page_publish, genre: @genre_1)
          get :show, id: page.id
          expect(assigns[:page]).to eq(page)
        end

        context "公開中コンテンツ・非公開コンテンツを持つ場合" do
          before do
            @page = create(:page_publish, genre: @genre_1)
            get :show, id: @page.id
          end

          it "公開済みコンテンツが取得できていること" do
            expect(assigns[:published]).to eq(@page.contents.last)
          end

          it "非公開コンテンツが取得できていること" do
            expect(assigns[:unpublished]).to eq(@page.contents.first)
          end
        end

        context "公開中コンテンツを持たない場合" do
          before do
            @page = create(:page_editing, genre: @genre_1)
            get :show, id: @page.id
          end

          it "公開済みコンテンツがnilであること" do
            expect(assigns[:published]).to be_nil
          end

          it "非公開コンテンツが取得できていること" do
            expect(assigns[:unpublished]).to eq(@page.contents.first)
          end
        end

        context "非公開コンテンツを持たない場合" do
          before do
            @page = create(:page_publish_without_private, genre: @genre_1)
            get :show, id: @page.id
          end

          it "公開済みコンテンツが取得できていること" do
            expect(assigns[:published]).to eq(@page.contents.first)
          end

          it "非公開コンテンツが nil であること" do
            expect(assigns[:unpublished]).to be_nil
          end
        end
      end
    end

    describe "GET histories" do
      let(:page) { create(:page) }

      subject { get :histories, id: page.id }

      before do
        @user = login(create(:user, section_id: @section_1.id))
      end

      describe "正常系" do
        it "テンプレートhistoriesを表示できること" do
          expect(subject).to render_template('histories')
        end

        context "公開履歴を持たない場合" do
          it "published_contentsが空であること" do
            subject
            expect(assigns[:published_contents].size).to eq(0)
          end
        end

        context "公開履歴を持つ場合" do
          let(:page) { create(:page_publish) }

          it "published_contentsに公開中のコンテンツが設定されていること" do
            subject
            expect(assigns[:published_contents].size).to eq(1)
            expect(assigns[:published_contents].first.admission).to eq(PageContent.page_status[:publish])
          end
        end

        context "公開待ちページを持つ場合" do
          let(:page) { create(:page_waiting) }

          it "反映処理未許可フラグがtrueになること" do
            subject
            expect(assigns[:unreflectable]).to be_true
          end
        end

        context "公開依頼待ちページを持つ場合" do
          let(:page) { create(:page_request) }

          context "ログインユーザがHP担当者の場合" do
            before do
              @user = login(create(:normal_user))
            end

            it "反映処理未許可フラグがtrueになること" do
              subject
              expect(assigns[:unreflectable]).to be_true
            end
          end

          context "ログインユーザがHP担当者以外場合" do
            it "反映処理未許可フラグがfalseになること" do
              subject
              expect(assigns[:unreflectable]).to be_false
            end
          end
        end
      end
    end

    describe "POST reflect" do
      let(:page) { create(:page_editing) }
      let(:page_content) {
        create(:page_content_publish,
          content: %Q(<div class="#{PageContent.editable_class[:field]}"><h1>reflected!</h1>\n</div>\n)
        )
      }

      subject { post :reflect, id: page.id, content_id: page_content.id }

      before do
        @user = login(create(:user, section_id: @section_1.id))
      end

      describe "正常系" do
        it "ページ詳細画面にリダイレクトされること" do
          expect(subject).to redirect_to(susanoo_page_path(page))
        end

        it "編集中コンテンツの内容が更新されること" do
          content = page_content.content
          subject
          expect(page.reload.editing_content.content.gsub("\n", "")).to eq(content.gsub("\n", ""))
        end
      end

      describe "異常系" do
        let(:page) { create(:page_waiting) }

        it "ページ詳細画面にリダイレクトされること" do
          expect(subject).to redirect_to(susanoo_page_path(page))
        end

        it "編集中コンテンツの内容が更新されないこと" do
          content = page.editing_content.content
          subject
          expect(page.reload.editing_content.content).to eq(content)
        end
      end
    end

    describe "GET new" do
      before do
        login create(:user, section_id: @section_1.id)
      end

      describe "正常系" do
        let(:genre) { @genre_1 }

        it "テンプレートshowを表示できること" do
          get :new
          expect(response).to render_template('new')
        end

        it "pageオブジェクトが取得できていること" do
          get :new
          expect(assigns[:page]).to be_instance_of(Page)
        end

        context 'genre_id を指定する場合' do
          before do
            get :new, genre_id: genre.id
          end

          it "genreオブジェクトが取得できていること" do
            expect(assigns[:genre]).to eq(genre)
          end

          it "pageオブジェクトは新規レコードであること" do
            expect(assigns[:page]).to be_new_record
          end

          it "pageオブジェクトはgenreオブジェクトを持つこと" do
            expect(assigns[:page].genre).to eq(genre)
          end
        end

        context 'genre_id を指定しない場合' do
          before do
            get :new
          end

          it "genreオブジェクトはnilであること" do
            expect(assigns[:genre]).to be_nil
          end

          it "pageオブジェクトは新規レコードであること" do
            expect(assigns[:page]).to be_new_record
          end

          it "pageオブジェクトはgenreオブジェクトを持たないこと" do
            expect(assigns[:page].genre).to be_nil
          end
        end
      end
    end

    describe "GET move" do
      let(:genre) { create(:genre) }
      let(:to_genre) { create(:genre) }

      subject { get :move, id: page.id, genre_id: to_genre.id }

      before do
        @user = login(create(:user))
      end

      describe "正常系" do
        let(:page) { create(:page, genre: genre) }

        it "ページ詳細画面にリダイレクトされること" do
          expect(subject).to redirect_to(susanoo_genres_path(genre_id: to_genre.id))
        end

        it "ページのフォルダが変更されること" do
          subject
          expect(page.reload.genre_id ).to eq(to_genre.id)
        end
      end

      describe "異常系" do
        let(:page) { create(:page_publish, genre: genre) }

        it "ページ詳細画面にリダイレクトされること" do
          expect(subject).to redirect_to(susanoo_genres_path(genre_id: genre.id))
        end

        it "ページのフォルダが変更されないこと" do
          subject
          expect(page.reload.genre_id).to eq(genre.id)
        end
      end
    end

    describe "GET select_copy_page" do
      let(:page) { create(:page, genre: @genre_1) }

      before do
        login create(:normal_user, section_id: @section_1.id)

        @published = create(:page_content_publish, page: page)
        @unpublished = create(:page_content_editing, page: page)
      end

      describe "正常系" do
        subject { get :select_copy_page, id: page.id, format: 'js'}

        it "テンプレートselect_copy_pageを表示できること" do
          expect(subject).to render_template('select_copy_page')
        end

        it "publishedコンテンツが取得できていること" do
          subject
          expect(assigns[:published].id).to eql(@published.id)
        end

        it "unpublishedコンテンツが取得できていること" do
          subject
          expect(assigns[:unpublished].id).to eql(@unpublished.id)
        end
      end
    end
  end
end
