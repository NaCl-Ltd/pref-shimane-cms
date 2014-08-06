require 'spec_helper'

describe Susanoo::UsersController do

  let(:valid_attributes) { {  } }
  let(:valid_session) { {} }

  describe "フィルタ" do
    controller do
      %w(index new create edit update destroy login logout authenticate).each do |act|
        define_method(act) do
          render text: "ok"
        end
      end
    end

    before do
      @routes.draw do
        resources :anonymous do
          member do
            delete :logout
          end
          collection do
            get :login
            get :authenticate
          end
        end
      end
    end

    describe "lonin_required" do
      let(:user) { create(:user) }

      shared_examples_for "未ログイン時のアクセス制限" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、ログイン画面が表示されること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end
      end

      shared_examples_for "ログイン時のアクセス制限"  do |met, act|
        before { login(user) }
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :edit) {before{get :edit, id: user.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update) {before{patch :update, id: user.id}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :edit) {before{get :edit, id: user.id}}
        it_behaves_like("ログイン時のアクセス制限", :patch, :update) {before{patch :update, id: user.id}}
      end
    end
  end

  describe "アクション" do
    describe "GET login" do
      context "未ログイン状態の場合" do
        before do
          get :login
        end

        it "ログイン画面が表示されること" do
          expect(assigns(:user)).not_to be_nil
          expect(response).to be_successful
          expect(response).to render_template("login")
        end
      end

      context "ログイン状態の場合" do
        before do
          @user = login(create(:user))
          get :login
        end

        it "トップページへリダイレクトされること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end
      end
    end

    describe "POST authenticate" do
      before do
        @user = create(:user, password: "password")
      end

      context "未ログイン状態の場合" do
        context "正しい組み合わせのID・パスワードを入力する" do
          before do
            post :authenticate, user: {login: @user.login, password: "password" }
          end

          it "指定したユーザでログインできていること" do
            expect(current_user).to eq @user.id
          end

          it "トップページへリダイレクトされること" do
            expect(response).to redirect_to(susanoo_dashboards_path)
          end

          it "ログインメッセージが表示されること" do
            expect(flash[:notice]).to eq I18n.t("susanoo.users.authenticate.success")
          end
        end

        context "誤った組み合わせのID・パスワードを入力する" do
          before do
            post :authenticate, user: {login: @user.login, password: "XpasswordX" }
          end

          it "ログインできていないこと" do
            expect(current_user).to be_nil
          end

          it "ログイン画面が表示されること" do
          expect(response).to be_successful
          expect(response).to render_template("login")
          end

          it "エラーメッセージが表示されること" do
            expect(flash[:alert]).to eq I18n.t("susanoo.users.authenticate.failure")
          end
        end
      end

      context "ログイン状態の場合" do
        before do
          @user1 = create(:user, password: "password")
          @user2 = create(:user, password: "password")
          login(@user1)
          post :authenticate, user: {login: @user2.login, password: "password" }
        end

        it "ログインユーザが変更されないこと" do
          expect(current_user).to eq @user1.id
        end

        it "トップページへリダイレクトされること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end

        it "ログインメッセージが表示されること" do
          expect(flash[:notice]).to eq I18n.t("shared.notice.login_not_required")
        end
      end
    end

    describe "DELETE logout" do
      context "ログイン状態の場合" do
        before do
          @user = login(create(:user))
          delete :logout, id: @user.id
        end

        it "未ログイン状態に変更されること" do
          expect(current_user).to be_nil
        end

        it "ログイン画面へリダイレクトされること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end

        it "ログアウトメッセージが表示されること" do
          expect(flash[:notice]).to eq I18n.t("susanoo.users.logout.success")
        end
      end

      context "未ログイン状態の場合" do
        before do
          @user = create(:user)
          delete :logout, id: @user.id
        end

        it "ログインしていないこと" do
          expect(current_user).to be_nil
        end

        it "ログイン画面へリダイレクトされること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end

        it "ログインメッセージが表示されること" do
          expect(flash[:notice]).to eq I18n.t("shared.notice.login_required")
        end
      end
    end

    describe "GET edit" do
      let(:user) { create(:user) }

      before do
        login(user)
      end

      describe "正常系" do
        subject { get :edit, id: user.id }

        context '運用管理者の場合' do
          let(:user) { create(:user) }

          it "テンプレートeditを表示されること" do
            expect(subject).to render_template('edit')
          end

          it "インスタンス変数@userが設定されていること" do
            subject
            expect(assigns(:user)).to eq user
          end
        end

        context '情報提供責任者の場合' do
          let(:user) { create(:section_user) }

          it "テンプレートeditを表示されること" do
            expect(subject).to render_template('edit')
          end

          it "インスタンス変数@userが設定されていること" do
            subject
            expect(assigns(:user)).to eq user
          end
        end

        context 'ホームページ担当者の場合' do
          let(:user) { create(:normal_user) }

          it "テンプレートeditを表示されること" do
            expect(subject).to render_template('edit')
          end

          it "インスタンス変数@userが設定されていること" do
            subject
            expect(assigns(:user)).to eq user
          end
        end
      end
    end

    describe "PATCH update" do
      before do
        login(user)
      end

      subject { patch :update, action_params.merge(id: user.id) }

      let(:user) { create(:user, password: now_password, password_confirmation: now_password) }
      let(:action_params) do
        { user: {
            now: {
              password: now_password,
            },
            new: {
              password: new_password,
              password_confirmation: new_password_confirmation,
            }
          } 
        }
      end
      let(:now_password) { 'password' }
      let(:new_password) { '12345678' }
      let(:new_password_confirmation) { '12345678' }

      describe "正常系" do
        context '運用管理者の場合' do
          let(:user) { create(:user, password: now_password, password_confirmation: now_password) }

          it "パスワード変更画面へリダイレクトすること" do
            expect(subject).to redirect_to(edit_susanoo_user_path(user))
          end

          it "変更成功のメッセージが表示されること" do
            subject
            expect(flash[:notice]).to eq(
              I18n.t("susanoo.users.update.success")
            )
          end

          it "パスワードが変更されること" do
            subject
            expect(user.reload.password).to eq User.encrypt(new_password)
          end
        end

        context '情報提供責任者の場合' do
          let(:user) { create(:section_user, password: now_password) }

          it "パスワード変更画面へリダイレクトすること" do
            expect(subject).to redirect_to(edit_susanoo_user_path(user))
          end

          it "変更成功のメッセージが表示されること" do
            subject
            expect(flash[:notice]).to eq(
              I18n.t("susanoo.users.update.success")
            )
          end

          it "パスワードが変更されること" do
            subject
            expect(user.reload.password).to eq User.encrypt(new_password)
          end
        end

        context 'ホームページ担当者の場合' do
          let(:user) { create(:normal_user, password: now_password) }

          it "パスワード変更画面へリダイレクトすること" do
            expect(subject).to redirect_to(edit_susanoo_user_path(user))
          end

          it "変更成功のメッセージが表示されること" do
            subject
            expect(flash[:notice]).to eq(
              I18n.t("susanoo.users.update.success")
            )
          end

          it "パスワードが変更されること" do
            subject
            expect(user.reload.password).to eq User.encrypt(new_password)
          end
        end
      end

      describe "異常系" do
        context '現在のパスワードを間違えた場合' do
          let(:user) { create(:user, password: 'pass1234', password_confirmation: 'pass1234') }

          it "テンプレートeditを表示されること" do
            expect(subject).to render_template('edit')
          end

          it "メッセージは表示されないこと" do
            subject
            expect(flash[:notice]).to be_nil
          end

          it "インスタンス変数@userが設定されていること" do
            subject
            expect(assigns(:user)).to eq user
          end

          it "エラーメッセージは表示されること" do
            subject
            expect(assigns(:user).errors.full_messages).to match_array([
              I18n.t("susanoo.users.update.password_mismatch"),
            ])
          end

          it "パスワードが変更されないこと" do
            subject
            expect(user.reload.password).to eq User.encrypt('pass1234')
          end
        end

        context 'バリデーションに失敗する場合' do
          let(:user) { create(:user, password: now_password, password_confirmation: now_password) }
          let(:new_password_confirmation) { 'pass1234' }

          it "テンプレートeditを表示されること" do
            expect(subject).to render_template('edit')
          end

          it "メッセージは表示されないこと" do
            subject
            expect(flash[:notice]).to be_nil
          end

          it "インスタンス変数@userが設定されていること" do
            subject
            expect(assigns(:user)).to eq user
          end

          it "エラーメッセージは表示されること" do
            subject
            expect(assigns(:user).errors.full_messages).to match_array([
              %{#{User.human_attribute_name(:password_confirmation)} #{I18n.t("activerecord.errors.messages.confirmation")}},
            ])
          end

          it "パスワードが変更されないこと" do
            subject
            expect(user.reload.password).to eq User.encrypt(now_password)
          end
        end
      end
    end
  end
end
