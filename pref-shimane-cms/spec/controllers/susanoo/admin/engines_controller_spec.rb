require 'spec_helper'

describe Susanoo::Admin::EnginesController do
  describe "フィルタ" do
    describe "admin_required" do
      shared_examples_for "未ログイン時のアクセス制限" do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、ログイン画面が表示されること" do
          expect(response).to redirect_to(login_susanoo_users_path)
        end
      end

      shared_examples_for "運用管理者ログイン時のアクセス制限"  do |met, act|
        before{@user = login(create(:user))}
        it "#{met.upcase} #{act}にアクセスしたとき、okが返ること" do
          (response.body == "ok").should be_true
        end
      end

      shared_examples_for "情報提供責任者ログイン時のアクセス制限"  do |met, act|
        before{@user = login(create(:section_user))}
        it "#{met.upcase} #{act}にアクセスしたとき、トップページへリダイレクトされること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end
      end

      shared_examples_for "一般ユーザログイン時のアクセス制限" do |met, act|
        before{@user = login(create(:normal_user))}
        it "#{met.upcase} #{act}にアクセスしたとき、トップページへリダイレクトされること" do
          expect(response).to redirect_to(susanoo_dashboards_path)
        end
      end

      controller do
        %w(index change_state).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:set_division).and_return(true)
        @routes.draw do
          resources :anonymous, only: [:index] do
            member do
              post :change_state
            end
          end
        end
        @engine = create(:engine_master)
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index)         {before{get :index}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :change_state)           {before{get :change_state, id: @engine.id}}
      end

      context "ログイン状態" do
        context "運用管理者の場合" do
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :change_state)           {before{get :change_state, id: @engine.id}}
        end

        context "情報提供責任者の場合" do
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :change_state)           {before{get :change_state, id: @engine.id}}
        end

        context "一般ユーザの場合" do
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :change_state)           {before{get :change_state, id: @engine.id}}
        end
      end
    end

    describe "set_division" do
      controller do
        %w(change_state).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:admin_required).and_return(true)
        @routes.draw do
          resources :anonymous, only: [:index] do
            member do
              get :change_state
            end
          end
        end

        @engine = create(:engine_master)
      end

      shared_examples_for "インスタンス変数@engineが正しく設定されているかの検証" do
        it "インスタンス変数@engineがEngineMasterクラスのインスタンスであること" do
          assigns[:engine].should be_kind_of(EngineMaster)
        end

        it "インスタンス変数@engineのidがパラメータ:idで送った値と等しいこと" do
          expect(assigns[:engine].id).to eq(@engine.id)
        end
      end

      context "GET change_stateにアクセスしたとき" do
        before do
          get :change_state, id: @engine.id
        end
        it_behaves_like "インスタンス変数@engineが正しく設定されているかの検証"
      end
    end
  end

  describe "アクション" do
    before do
      controller.stub(:admin_required).and_return(true)
    end

    describe "GET index" do
      describe "正常系" do
        before do
          10.times{create(:engine_master)}
        end

        subject {get :index}

        it "EngineMasterからID順で全件取得していること" do
          subject
          expect(assigns[:engines]).to eq(EngineMaster.order("id"))
        end

        it "indexをrenderしていること" do
          expect(subject).to render_template(:index)
        end

        context "EngineMasterに登録されていないが設定されているEngineがある場合" do
          it "該当のエンジンがEngineMasterに追加されること" do
            klass = Struct.new(:engine_name)
            klasses = [klass.new("example")]
            EngineMaster.stub(:engine_classes).and_return(klasses)
            expect{subject}.to change(EngineMaster, :count).by(1)
          end
        end

        context "EngineMasterに登録されていて設定されているEngineがある場合" do
          it "該当のエンジンがEngineMasterに追加されないこと" do
            engine = create(:engine_master)
            klass = Struct.new(:engine_name)
            klasses = [klass.new(engine.name)]
            EngineMaster.stub(:engine_classes).and_return(klasses)
            expect{subject}.to change(EngineMaster, :count).by(0)
          end
        end
      end
    end

    describe "GET change_state" do
      before do
        @engine = create(:engine_master)
      end

      subject {get :change_state, id: @engine.id}

      describe "正常系" do
        it "オプション管理画面トップへリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_admin_engines_path)
        end

        context "保存処理に成功した場合" do
          it "flash[:notice]にメッセージが設定されていること" do
            EngineMaster.any_instance.stub(:save).and_return(true)
            subject
            expect(flash[:notice]).to eq(I18n.t("susanoo.admin.engines.change_state.success"))
          end
        end

        context "選択したエンジンレコードのenableがTrueの場合" do
          it "選択したエンジンレコードのenableをFalseにする" do
            engine = create(:engine_master, enable: true)
            get :change_state, id: engine.id
            expect(engine.reload.enable).to be_false
          end
        end

        context "選択したエンジンレコードのenableがFalseの場合" do
          it "選択したエンジンレコードのenableをTrueにする" do
            engine = create(:engine_master, enable: false)
            get :change_state, id: engine.id
            expect(engine.reload.enable).to be_true
          end
        end
      end

      describe "異常系" do
        context "保存処理に失敗した場合" do
          it "flash[:alert]にメッセージが設定されていること" do
            EngineMaster.any_instance.stub(:save).and_return(false)
            subject
            expect(flash[:alert]).to eq(I18n.t("susanoo.admin.engines.change_state.alert"))
          end
        end
      end
    end
  end
end
