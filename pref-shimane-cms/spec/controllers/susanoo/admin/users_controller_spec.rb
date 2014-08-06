require 'spec_helper'

describe Susanoo::Admin::UsersController do

  shared_examples_for "未ログイン時のアクセス制限" do |action|
    it "#{action} ログイン画面にリダイレクトされること" do
      expect(response).to redirect_to(login_susanoo_users_path)
    end
  end

  shared_examples_for "情報提供責任者ログイン時のアクセス制限" do |action|
    before{@user = login(create(:section_user))}
    it "#{action} トップページへリダイレクトされること" do
      expect(response).to redirect_to(susanoo_dashboards_path)
    end
  end

  shared_examples_for "一般ユーザログイン時のアクセス制限" do |action|
    before{@user = login(create(:normal_user))}
    it "#{action} トップページへリダイレクトされること" do
      expect(response).to redirect_to(susanoo_dashboards_path)
    end
  end

  shared_examples_for "Userの取得" do |action|
    it "#{action} @userにセットしていること" do
      expect(assigns[:user]).to eq(@user)
    end
  end

  describe "フィルタ" do
    controller do
      [:index, :new, :create, :edit, :update, :destroy].each do |method|
        define_method(method) do
          render text: :OK
        end
      end
    end

    describe "admin_required" do
      context "未ログイン状態の場合" do
        shared_example_name =  "未ログイン時のアクセス制限"

        it_should_behave_like(shared_example_name, :index) { before {get :index } }
        it_should_behave_like(shared_example_name, :new) { before {get :new } }
        it_should_behave_like(shared_example_name, :create) { before {post :create } }
        it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
        it_should_behave_like(shared_example_name, :update) { before {patch :update, id: 1 } }
        it_should_behave_like(shared_example_name, :destory) { before {delete :destroy, id: 1 } }
      end

      context "ログイン状態の場合" do
        context "情報提供責任者の場合" do
          shared_example_name = "情報提供責任者ログイン時のアクセス制限"

          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :new) { before {get :new } }
          it_should_behave_like(shared_example_name, :create) { before {post :create } }
          it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
          it_should_behave_like(shared_example_name, :update) { before {patch :update, id: 1 } }
          it_should_behave_like(shared_example_name, :destory) { before {delete :destroy, id: 1 } }
        end

        context "一般ユーザの場合" do
          shared_example_name = "一般ユーザログイン時のアクセス制限"

          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :new) { before {get :new } }
          it_should_behave_like(shared_example_name, :create) { before {post :create } }
          it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
          it_should_behave_like(shared_example_name, :update) { before {patch :update, id: 1 } }
          it_should_behave_like(shared_example_name, :destory) { before {delete :destroy, id: 1 } }
        end
      end
    end

    describe "set_user" do
      before do
        @user = login(create(:user))
        controller.stub(:user_params).and_return(true)
      end

      shared_example_name = "Userの取得"

      it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: @user.id } }
      it_should_behave_like(shared_example_name, :update) { before {patch :update, id: @user.id } }
      it_should_behave_like(shared_example_name, :destory) { before {delete :destroy, id: @user.id } }
    end
  end


  describe "アクション" do
    describe "GET index" do
      describe "正常系" do
        let(:users)    { User.all.page(nil) }

        before do
          3.times do |section_id|
            10.times do
              create(:user, section_id: section_id)
            end
          end
          @user = login(create(:user))
        end

        context "section_idがパラメータに含まれていない" do
          it "ユーザを全件取得していること" do
            get :index
            expect(assigns(:users).to_a).to eq(users.to_a)
          end
        end

        context "section_idがパラメータに含まれている" do
          let(:section_id) { 1 }
          it "所属に紐づくユーザを全件取得していること" do
            get :index, section_id: section_id
            expect(assigns(:users).to_a.all?{|u| u.section_id == section_id}).to be_true
          end
        end

        context 'アクセスがAJAXの場合' do
          it 'テンプレートをrenderしていること' do
            xhr :get,  :index
            expect(response).to render_template('_user_row')
          end
        end
      end
    end

    describe "GET new" do
      describe "正常系" do
        let(:sections) { Section.all }

        before do
          @user  = login(create(:user))
          get :new
        end

        it "新しいUserインスタンスを作成していること" do
          expect(assigns(:user).new_record?).to be_true
        end
      end
    end

    describe "GET edit" do
      describe "正常系" do
        before do
          @user  = login(create(:user))
        end

        subject{ get :edit, id: @user.id}

        it "editをrenderしていること" do
          expect(subject).to render_template(:edit)
        end
      end
    end

    describe "POST create" do
      let(:user) { {name: 'test'} }

      before do
        @user  = login(create(:user))
      end

      subject { post :create, {user: user} }

      describe "正常系" do
        context "バリデーションに成功した場合" do
          before :each do
            User.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "一覧画面へリダイレクトすること" do
              User.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(susanoo_admin_users_path)
            end
          end

          context "保存に失敗した場合" do
            it "作成画面を再描画していること" do
              User.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template(:new)
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          let(:sections) { Section.all }

          it "作成画面を再描画していること" do
            expect(subject).to render_template(:new)
          end
        end
      end
    end

    describe "PATCH update" do
      let(:user) { {name: ''} }

      before do
        @user  = login(create(:user))
      end

      subject { patch :update, {id: @user.id, user: user} }


      describe "正常系" do
        context "バリデーションに成功した場合" do
          before :each do
            User.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "一覧画面へリダイレクトすること" do
              User.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(susanoo_admin_users_path)
            end
          end

          context "保存に失敗した場合" do
            it "作成画面を再描画していること" do
              User.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template(:edit)
            end
          end
        end

        context "パスワードパラメータが存在している場合" do
          let(:new_password) { "testtesttest" }

          it "パスワードが変更されていること" do
            patch :update, {id: @user.id, user: @user.attributes.except(:id).merge(
              password:              new_password,
              password_confirmation: new_password
            )}
            @user.reload
            expect(@user.password).to eq(::User.encrypt(new_password))
          end
        end

        context "パスワードパラメータが存在していない場合" do
          it "パスワードが変更されていないこと" do
            old_password = @user.password
            patch :update, {id: @user.id, user: @user.attributes.except(:id, :password)}
            @user.reload
            expect(@user.password).to eq(old_password)
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            User.any_instance.stub(:valid?).and_return(false)
          end

          it "作成画面を再描画していること" do
            expect(subject).to render_template(:edit)
          end
        end
      end
    end

    describe "delete destroy" do
      describe "正常系" do
        before do
          @user  = login(create(:user))
        end

        subject { delete :destroy, id: @user.id }

        it "Userの数が減っていること" do
          old_count = User.count
          expect{subject}.to change {User.count}.from(old_count).to(old_count - 1)
        end

        it "一覧画面へリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_admin_users_path)
        end
      end
    end
  end

end
