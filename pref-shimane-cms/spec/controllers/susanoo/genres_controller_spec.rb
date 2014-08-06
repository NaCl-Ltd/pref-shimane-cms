require 'spec_helper'

describe Susanoo::GenresController do
  let(:valid_attributes) { {  } }

  let(:valid_session) { {} }

  describe "フィルタ" do
    controller do
      %w(index new create edit update destroy move select_genre select_resource select_division).each do |act|
        define_method(act) do
          render text: "ok"
        end
      end
    end

    before do
      @division = create(:division)
      @sections = create_list(:section, 3, division: @division)
      @user = create(:user, section: @sections.first)
      @top = create(:top_genre, section: @sections.first)
      @genre = create(:genre, parent: @top, section: @sections.first)
      @routes.draw do
        resources :anonymous do
          member do
            patch :move
          end
          collection do
            get :select_genre
            get :select_resource
            get :select_division
          end
        end
      end
    end

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

      before do
        controller.stub(:set_divisions_and_sections).and_return(true)
        controller.stub(:set_genre).and_return(true)
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index) {before{get :index}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :new) {before{get :new}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create) {before{post :create}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :edit) {before{get :edit, id: @genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update) {before{patch :update, id: @genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy, id: @genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :move) {before{patch :move, id: @genre.id}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :select_genre) {before{get :select_genre}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :select_resource) {before{get :select_resource}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :select_division) {before{get :select_division}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :index) {before{get :index}}
        it_behaves_like("ログイン時のアクセス制限", :get, :new) {before{get :new, parent_id: @top.id}}
        it_behaves_like("ログイン時のアクセス制限", :post, :create) {before{post :create}}
        it_behaves_like("ログイン時のアクセス制限", :get, :edit) {before{get :edit, id: @genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :patch, :update) {before{patch :update, id: @genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :delete, :destroy){before{delete :destroy, id: @genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :patch, :move) {before{patch :move, id: @genre.id}}
        it_behaves_like("ログイン時のアクセス制限", :get, :select_genre) {before{get :select_genre}}
        it_behaves_like("ログイン時のアクセス制限", :get, :select_resource) {before{get :select_resource}}
        it_behaves_like("ログイン時のアクセス制限", :get, :select_division) {before{get :select_division}}
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
        controller.stub(:lonin_required).and_return(true)
        login(@user)
      end

      it_behaves_like("部局と所属の設定", :get, :new) { before { get :new, parent_id: @genre.id } }
      it_behaves_like("部局と所属の設定", :get, :edit) { before { get :edit, id: @genre.id } }
    end

    describe "set_genre" do
      shared_examples_for "フォルダの設定"  do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、Genre のインスタンスが生成されていること" do
          expect(assigns[:genre]).to eq(@genre)
        end
      end

      before do
        controller.stub(:lonin_required).and_return(true)
        controller.stub(:set_divisions_and_sections).and_return(true)
        login(@user)
      end

      it_behaves_like("フォルダの設定", :get, :edit) {before{get :edit, id: @genre.id}}
      it_behaves_like("フォルダの設定", :patch, :update) {before{patch :update, id: @genre.id}}
      it_behaves_like("フォルダの設定", :delete, :destroy){before{delete :destroy, id: @genre.id}}
    end

  end

  describe "アクション" do
    shared_context "フォルダ初期化" do
      let!(:division) { create(:division) }
      let!(:section1) { create(:section_without_genres, division: division) }
      let!(:section2) { create(:section_without_genres, division: division) }
      let!(:section3) { create(:section_without_genres, division: division) }

      let!(:top) { create(:top_genre, section: section1, deletable: false) }
      let!(:genre_1) { create(:genre, parent: top, section: section1, deletable: true).reload }
      let!(:genre_2) { create(:genre, parent: top, section: section2, deletable: true).reload }
      let!(:genre_3) { create(:genre, parent: top, section: section3, deletable: false).reload }

      let!(:admin_user) { create(:user, section: section1) }
    end

    describe "GET index" do
    end

    describe "DELETE destroy" do
      include_context 'フォルダ初期化'

      describe "正常系" do
        before { login admin_user }

        context "削除可能なフォルダを指定" do
          subject { delete :destroy, id: genre_2.id }

          it "フォルダ一覧画面へリダイレクトすること" do
            expect(subject).to redirect_to(
              susanoo_genres_path(genre_id: genre_2.parent_id)
            )
          end

          it "フォルダが削除できること" do
            expect{ subject }.to change(Genre, :count).by(-1)
          end

          it "フォルダの所属のトップフォルダがnilになること" do
            section2.update(top_genre_id: genre_2.id)
            expect(section2.reload.top_genre_id).to eq(genre_2.id)
            subject
            expect(section2.reload.top_genre_id).to be_nil
          end

          it "削除成功メッセージが表示されること" do
            subject
            expect(flash[:notice]).to eq(
              I18n.t("susanoo.genres.destroy.success", name: genre_2.title)
            )
          end
        end

        context "削除できないフォルダを指定" do
          subject { delete :destroy, id: genre_3.id }

          it "フォルダ一覧画面へリダイレクトすること" do
            expect(subject).to redirect_to(
              susanoo_genres_path(genre_id: genre_3.id)
            )
          end

          it "フォルダが削除されないこと" do
            expect{ subject }.to change(Genre, :count).by(0)
          end

          it "関連するイベント参照が削除されないこと" do
            expect{ subject }.to change(EventReferer, :count).by(0)
          end

          it "削除不能メッセージが表示されること" do
            subject
            expect(flash[:notice]).to eq(
              I18n.t("susanoo.genres.destroy.not_deletable", name: genre_3.title)
            )
          end
        end
      end
    end

    describe "GET copy" do
      let(:top) { create(:top_genre) }
      let(:genre) { create(:genre, parent_id: top) }
      let(:to_genre) { create(:genre, parent_id: top) }

      subject { get :copy, id: genre.id, genre_id: to_genre.id }

      before do
        @user = login(create(:user))
      end

      describe "正常系" do
        it "ページ詳細画面にリダイレクトされること" do
          expect(subject).to redirect_to(susanoo_genres_path(genre_id: to_genre.id))
        end

        it "フォルダのコピーができること" do
          subject
          expect(to_genre.children.exists?).to be_true
        end
      end

      describe "異常系" do
        let(:to_genre) { genre }

        it "ページ詳細画面にリダイレクトされること" do
          expect(subject).to redirect_to(susanoo_genres_path(genre_id: genre.id))
        end

        it "コピーが作成されないこと" do
          subject
          expect(genre.children.exists?).to be_false
        end
      end
    end

    describe "GET move_order" do
      before do
        @user = login(create(:user))
        @top = create(:top_genre)
        @genre_1 = create(:genre, parent_id: @top.id, no: 1)
        @genre_2 = create(:genre, parent_id: @top.id, no: 2)
        @genre_3 = create(:genre, parent_id: @top.id, no: 3)
      end

      describe "move_higher" do
        subject { get :move_order, id: @genre_2.id, type: :move_higher, format: :js}

        describe "正常系" do
          before { subject }

          it "表示順が変更されること" do
            expect(@genre_2.reload.no).to eq(1)
            expect(@genre_1.reload.no).to eq(2)
          end

          it "インスタン変数 genre に親フォルダが設定されること" do
            expect(assigns[:genre]).to eq(@top)
          end

          it "インスタン変数 genres に親フォルダに属するフォルダが設定されること" do
            genres = Genre.where(parent_id: @top.id).order('no')
            expect(assigns[:genres]).to eq(genres.to_a)
          end
        end
      end

      describe "move_lower" do
        subject { get :move_order, id: @genre_2.id, type: :move_lower, format: :js}

        describe "正常系" do
          before { subject }

          it "表示順が変更されること" do
            expect(@genre_2.reload.no).to eq(3)
            expect(@genre_3.reload.no).to eq(2)
          end

          it "インスタンス変数 genre に親フォルダが設定されること" do
            expect(assigns[:genre]).to eq(@top)
          end

          it "インスタンス変数 genres に親フォルダに属するフォルダが設定されること" do
            genres = Genre.where(parent_id: @top.id).order('no')
            expect(assigns[:genres]).to eq(genres.to_a)
          end
        end
      end
    end
  end
end
