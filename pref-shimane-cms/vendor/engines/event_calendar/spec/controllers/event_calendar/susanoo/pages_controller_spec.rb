require 'spec_helper'

describe EventCalendar::Susanoo::PagesController do
  describe "フィルタ" do
    controller do
      %w(index new create select select_event_top).each do |act|
        define_method(act) do
          render text: "ok"
        end
      end
    end

    before do
      @division = create(:division)
      @sections = create_list(:section, 3, division: @division)
      @user = create(:user, section: @sections.first)

      @routes.draw do
        resources :anonymous do
          collection do
            get :select
            get :select_event_top
          end
        end
      end
    end

    describe "lonin_required" do
      before do
        controller.stub(:enable_engine_required).and_return(true)
        controller.stub(:set_event_tops_and_category_folders).and_return(true)
      end

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

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :new) {before{get :new, use_route: :event_calendar}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create) {before{post :create, use_route: :event_calendar}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :select) {before{get :select, use_route: :event_calendar}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :select_event_top) {before{get :select, use_route: :event_calendar}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :new) {before{get :new, use_route: :event_calendar}}
        it_behaves_like("ログイン時のアクセス制限", :post, :create) {before{post :create, use_route: :event_calendar}}
        it_behaves_like("ログイン時のアクセス制限", :get, :select) {before{get :select, use_route: :event_calendar}}
        it_behaves_like("ログイン時のアクセス制限", :get, :select_event_top) {before{get :select, use_route: :event_calendar}}
      end
    end

    describe "enable_engine_required" do
      before do
        controller.stub(:login_required).and_return(true)
        controller.stub(:set_event_tops_and_category_folders).and_return(true)
      end

      shared_examples_for "エンジンが有効な場合のアクセス制限" do |met, act|
        before{EngineMaster.stub(:enable?).and_return(true)}
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          expect(response.body).to eq("ok")
        end
      end

      shared_examples_for "エンジンが無効な場合のアクセス制限"  do |met, act|
        before{EngineMaster.stub(:enable?).and_return(false)}
        it "#{met.upcase} #{act}にアクセスしたとき、トップページへリダイレクトすること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end

        it "#{met.upcase} #{act}にアクセスしたとき、flash[:alert]にメッセージが設定されること" do
          expect(flash[:alert]).to eq(I18n.t("shared.engines.disable"))
        end
      end

      context "エンジンが有効な場合" do
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :new)           {before{get :new, use_route: :event_calendar}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :create)       {before{post :create, use_route: :event_calendar}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :select)           {before{get :select, use_route: :event_calendar}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :select_event_top)           {before{get :select, use_route: :event_calendar}}
      end

      context "エンジンが無効な場合" do
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :new)           {before{get :new, use_route: :event_calendar}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :create)       {before{post :create, use_route: :event_calendar}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :select)           {before{get :select, use_route: :event_calendar}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :select_event_top)           {before{get :select, use_route: :event_calendar}}
      end
    end

    describe "set_event_tops_and_category_folders" do
      shared_examples_for "イベントトップがある場合のGenreの設定"  do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、@event_topsと@category_foldersが空でないこと" do
          expect(assigns[:event_tops].count.zero?).to be_false
          expect(assigns[:category_folders].count.zero?).to be_false
        end
      end

      shared_examples_for "イベントトップがない場合のGenreの設定"  do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、@event_topsと@category_foldersが空であること" do
          expect(assigns[:event_tops].count.zero?).to be_true
          expect(assigns[:category_folders].count.zero?).to be_true
        end
      end

      before do
        controller.stub(:login_required).and_return(true)
        controller.stub(:enable_engine_required).and_return(true)
        login(@user)
      end

      context "イベントトップがある場合" do
        before do
          top_event = create(:genre, event_folder_type: Genre.event_folder_types[:top], parent: create(:top_genre, section: @user.section), section: @user.section)
          create(:genre, event_folder_type: Genre.event_folder_types[:category], parent: top_event)
        end

        it_behaves_like("イベントトップがある場合のGenreの設定", :get, :new) do
          before{get :new}
        end
      end

      context "イベントトップがない場合" do
        it_behaves_like("イベントトップがない場合のGenreの設定", :get, :new) do
          before{get :new}
        end
      end
    end
  end

  describe "アクション" do
    before do
      @division = create(:division)
      @sections = create_list(:section, 3, division: @division)
      @user = create(:user, section: @sections[0])
      controller.stub(:enable_engine_required).and_return(true)
      controller.stub(:genre_required).and_return(true)
      login(@user)
    end

    describe "GET new" do
      describe "正常系" do
        subject { get :new, use_route: :event_calendar }

        it "newをrenderしていること" do
          expect(subject).to render_template(:new)
        end

        it "pageオブジェクトが取得できていること" do
          subject
          expect(assigns[:page]).to be_a(Page)
        end

        it "pageオブジェクトが新規インスタンスであること" do
          subject
          expect(assigns[:page].new_record?).to be_true
        end
      end
    end

    describe "POST create" do
      let(:top_event) { create(:genre, event_folder_type: Genre.event_folder_types[:top], parent: create(:top_genre)) }
      let(:page_attributes) { {title: "イベントタイトル", name: "event_title", begin_event_date: Date.today, end_event_date: Date.today} }

      describe "正常系" do
        # NOTE: redirect先がevent_calendarでなくなるため
        routes { EventCalendar::Engine.routes }

        context "カテゴリフォルダを使用しない場合" do
          subject { post :create,  page: page_attributes.merge(event_top_id: top_event.id.to_s), :select_use_categroy_folder => "2", use_route: :event_calendar }

          it "Pageテーブルにレコードが1件追加されていること" do
            expect{subject}.to change(Page, :count).by(1)
          end

          it "作成されるページのgenre_idがイベントトップであること" do
            subject
            expect(assigns[:page].genre_id).to eq(top_event.id)
          end

          it "ページコンテンツ作成画面にリダイレクトすること" do
            expect(subject).to redirect_to(edit_susanoo_page_content_path(assigns[:page].contents.first, mode: "new_page"))
          end
        end

        context "カテゴリフォルダを使用する場合" do
          let(:category_folder) { create(:genre, parent: top_event, event_folder_type: Genre.event_folder_types[:category]) }

          subject { post :create, page: page_attributes.merge(event_top_id: top_event.id.to_s, genre_id: category_folder.id), :select_use_categroy_folder => "1", use_route: :event_calendar }

          it "Pageテーブルにレコードが1件追加されていること" do
            expect{subject}.to change(Page, :count).by(1)
          end

          it "作成されるページのgenre_idがカテゴリフォルダであること" do
            subject
            expect(assigns[:page].genre_id).to eq(category_folder.id)
          end

          it "ページコンテンツ作成画面にリダイレクトすること" do
            expect(subject).to redirect_to(edit_susanoo_page_content_path(assigns[:page].contents.first, mode: "new_page"))
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            @top_event = top_event
          end

          shared_examples_for "エラー処理" do
            subject { post :create, attributes }

            it "再度作成画面が描画されること" do
              expect(subject).to render_template("new")
            end

            it "pagesテーブルにレコードが追加されないこと" do
              expect{subject}.to change(Genre, :count).by(0)
            end
          end

          it_behaves_like "エラー処理" do
            let(:attributes) { { page: page_attributes.merge(name: "", event_top_id: top_event.id.to_s),
                select_use_categroy_folder: "2", use_route: :event_calendar } }
            let(:attributes) { { page: page_attributes.merge(begin_event_date: Date.today, end_event_date: Date.today - 1, event_top_id: top_event.id.to_s),
                select_use_categroy_folder: "2", use_route: :event_calendar } }
            let(:attributes) { { page: page_attributes.merge(begin_event_date: Date.today, end_event_date: Date.today + 31, event_top_id: top_event.id.to_s),
                select_use_categroy_folder: "2", use_route: :event_calendar } }
            let(:attributes) { { page: page_attributes.merge(event_top_id: top_event.id.to_s),
                select_use_categroy_folder: "1", use_route: :event_calendar } }
          end
        end
      end
    end
  end
end
