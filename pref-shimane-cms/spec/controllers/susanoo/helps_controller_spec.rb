require 'spec_helper'

describe Susanoo::HelpsController do
  before do
    controller.stub(:feature_check).and_return(true)
  end

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
        %w(index treeview show search).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        @routes.draw do
          resources :anonymous do
            collection do
              get :treeview
              post :search
            end
          end
        end
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index) {before{get :index}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :treeview) {before{get :treeview}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :show) {before{get :show, id: 1}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :search) {before{post :search}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :index) {before{get :index}}
        it_behaves_like("ログイン時のアクセス制限", :get, :treeview) {before{get :treeview}}
        it_behaves_like("ログイン時のアクセス制限", :get, :show) {before{get :show, id: 1}}
        it_behaves_like("ログイン時のアクセス制限", :post, :search) {before{post :search}}
      end
    end
  end

  describe "アクション" do
    before do
      login create(:user)
    end

    describe "GET index" do
      describe "正常系" do
        subject { get :index }

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "indexをrenderしていること" do
          expect(subject).to render_template(:index)
        end
      end
    end

    describe "GET treeview" do
      describe "正常系" do
        subject { get :treeview }

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "HelpCategoryにcategory_and_help_for_treeviewを呼び出していること" do
          HelpCategory.should_receive(:category_and_help_for_treeview)
          subject
        end
      end
    end

    describe "GET show" do
      before do
        @help = create(:help)
      end

      subject { get :show, id: @help.id }

      describe "正常系" do
        it "helpを取得していること" do
          subject
          expect(assigns[:help]).to eq(@help)
        end

        it "_showをrenderしていること" do
          expect(subject).to render_template(:_show)
        end
      end
    end

    describe "GET search" do
      subject { post :search }

      describe "正常系" do
        it "helpを取得していること" do
          HelpCategory.should_receive(:category_and_help_search)
          subject
        end
      end
    end
  end
end

