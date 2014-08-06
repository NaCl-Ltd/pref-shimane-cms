require 'spec_helper'

describe BlogManagement::Susanoo::GenresController do
  describe "フィルタ" do
    controller do
      %w(new create).each do |act|
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
        end
      end
    end

    describe "lonin_required" do
      before do
        controller.stub(:enable_engine_required).and_return(true)
        controller.stub(:set_divisions_and_sections).and_return(true)
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
        it_behaves_like("未ログイン時のアクセス制限", :get, :new) {before{get :new}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create) {before{post :create}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :new) {before{get :new}}
        it_behaves_like("ログイン時のアクセス制限", :post, :create) {before{post :create}}
      end
    end

    describe "enable_engine_required" do
      before do
        controller.stub(:login_required).and_return(true)
        controller.stub(:set_divisions_and_sections).and_return(true)
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
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :new)           {before{get :new, use_route: :blog_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :create)       {before{post :create, use_route: :blog_management}}
      end

      context "エンジンが無効な場合" do
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :new)           {before{get :new, use_route: :blog_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :create)       {before{post :create, use_route: :blog_management}}
      end
    end

    describe "set_divisions_and_sections" do
      shared_examples_for "部局と所属の設定"  do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、Division と Section のインスタンスが生成されていること" do
          expect(assigns[:division]).to eq(@division)
          expect(assigns[:sections]).to eq(@sections)
        end
      end

      before do
        controller.stub(:login_required).and_return(true)
        controller.stub(:enable_engine_required).and_return(true)
        login(@user)
      end

      it_behaves_like("部局と所属の設定", :get, :new) do
        before{get :new}
      end
    end
  end

  describe "アクション" do
    before do
      @division = create(:division)
      @sections = create_list(:section, 3, division: @division)
      @user = create(:user, section: @sections[0])
      controller.stub(:enable_engine_required).and_return(true)
      login(@user)
    end

    describe "GET new" do
      describe "正常系" do
        subject { get :new, use_route: :blog_management }

        it "newをrenderしていること" do
          expect(subject).to render_template(:new)
        end

        it "genreオブジェクトが取得できていること" do
          subject
          expect(assigns[:genre]).to be_a(Genre)
        end

        it "genreオブジェクトが新規インスタンスであること" do
          subject
          expect(assigns[:genre].new_record?).to be_true
        end
      end
    end

    describe "POST create" do
      before do
        @top_genre = create(:top_genre)
        @genre_attributes = attributes_for(:second_genre)
        @genre_attributes.merge!(parent_id: @top_genre.id, section_id: @user.id)
      end

      describe "正常系" do
        # NOTE: redirect先がblog_engineでなくなるため
        routes { BlogManagement::Engine.routes }

        subject { post :create,  genre: @genre_attributes, use_route: :blog_management }

        it "Genresテーブルにレコードが1件追加されていること" do
          expect{subject}.to change(Genre, :count).by(1)
        end

        it "ブログフォルダーとなるgenreのblog_folder_typeがtopであること" do
          subject
          expect(assigns[:genre].blog_folder_type).to eq(Genre.blog_folder_types[:top])
        end

        it "ページ一覧にリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_blogs_path)
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            @genre_attributes.merge!(name: "")
          end

          subject { post :create,  genre: @genre_attributes, use_route: :blog_management }

          it "再度作成画面が描画されること" do
            expect(subject).to render_template("new")
          end

          it "Genresテーブルにレコードが追加されないこと" do
            expect{subject}.to change(Genre, :count).by(0)
          end
        end
      end
    end
  end
end
