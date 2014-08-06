require 'spec_helper'

describe AdvertisementManagement::Susanoo::AdvertisementsController do
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
          expect(response.body).to eq("ok")
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
        %w(index new create edit update destroy update_sort show sort edit_state update_state show_file finish_sort).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:enable_engine_required).and_return(true)
        controller.stub(:set_advertisement).and_return(true)
        controller.stub(:state_editable).and_return(true)
        @routes.draw do
          resources :anonymous do
            collection do
              get :edit_state
              post :update_state
              get :sort
              post :update_sort
              post :finish_sort
            end

            member do
              get :show_file
            end
          end
        end
        @advertisement = create(:advertisement1)
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index)         {before{get :index, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :new)           {before{get :new, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create)       {before{post :create, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :show)          {before{get :show, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}

        it_behaves_like("未ログイン時のアクセス制限", :get, :edit_state)    {before{get :edit_state, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :update_state) {before{post :update_state, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :sort)          {before{get :sort, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :finish_sort)  {before{post :finish_sort, use_route: :advertisement_management}}

        it_behaves_like("未ログイン時のアクセス制限", :get, :show_file)       {before{get :show_file, id: @advertisement.id, use_route: :advertisement_management}}
      end

      context "ログイン状態" do
        context "運用管理者の場合" do
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :index)         {before{get :index, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :new)           {before{get :new, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :create)       {before{post :create, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :show)          {before{get :show, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}

          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :edit_state)    {before{get :edit_state, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :update_state) {before{post :update_state, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :sort)          {before{get :sort, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :finish_sort)  {before{post :finish_sort, use_route: :advertisement_management}}

          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :show_file)       {before{get :show_file, id: @advertisement.id, use_route: :advertisement_management}}
        end

        context "情報提供責任者の場合" do
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :index)         {before{get :index, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :new)           {before{get :new, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :create)       {before{post :create, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :show)          {before{get :show, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}

          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :edit_state)    {before{get :edit_state, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :update_state) {before{post :update_state, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :sort)          {before{get :sort, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :finish_sort)  {before{post :finish_sort, use_route: :advertisement_management}}

          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :show_file)       {before{get :show_file, id: @advertisement.id, use_route: :advertisement_management}}
        end

        context "一般ユーザの場合" do
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :index)         {before{get :index, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :new)           {before{get :new, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :create)       {before{post :create, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :show)          {before{get :show, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @advertisement.id, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}

          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :edit_state)    {before{get :edit_state, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :update_state) {before{post :update_state, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :sort)          {before{get :sort, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :finish_sort)  {before{post :finish_sort, use_route: :advertisement_management}}

          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :show_file)       {before{get :show_file, id: @advertisement.id, use_route: :advertisement_management}}
        end
      end
    end

    describe "enable_engine_required" do
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

      controller do
        %w(index new create edit update destroy update_sort show sort edit_state update_state show_file finish_sort).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:admin_required).and_return(true)
        controller.stub(:login_required).and_return(true)
        controller.stub(:state_editable).and_return(true)
        @routes.draw do
          resources :anonymous do
            collection do
              get :edit_state
              post :update_state
              get :sort
              post :update_sort
              post :finish_sort
            end

            member do
              get :show_file
            end
          end
        end
        @advertisement = create(:advertisement1)
      end

      context "エンジンが有効な場合" do
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :index)         {before{get :index, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :new)           {before{get :new, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :create)       {before{post :create, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :edit)          {before{get :edit, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :patch, :update)      {before{patch :update, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :show)          {before{get :show, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}

        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :edit_state)    {before{get :edit_state, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :update_state) {before{post :update_state, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :sort)          {before{get :sort, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}
        it_behaves_like("エンジンが有効な場合のアクセス制限", :post, :finish_sort)  {before{post :finish_sort, use_route: :advertisement_management}}

        it_behaves_like("エンジンが有効な場合のアクセス制限", :get, :show_file)       {before{get :show_file, id: @advertisement.id, use_route: :advertisement_management}}
      end

      context "エンジンが無効な場合" do
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :index)         {before{get :index, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :new)           {before{get :new, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :create)       {before{post :create, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :edit)          {before{get :edit, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :patch, :update)      {before{patch :update, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :show)          {before{get :show, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @advertisement.id, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}

        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :edit_state)    {before{get :edit_state, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :update_state) {before{post :update_state, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :sort)          {before{get :sort, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :update_sort)  {before{post :update_sort, use_route: :advertisement_management}}
        it_behaves_like("エンジンが無効な場合のアクセス制限", :post, :finish_sort)  {before{post :finish_sort, use_route: :advertisement_management}}

        it_behaves_like("エンジンが無効な場合のアクセス制限", :get, :show_file)       {before{get :show_file, id: @advertisement.id, use_route: :advertisement_management}}
      end
    end

    describe "set_advertisement" do
      controller do
        %w(edit update destroy show show_file).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:enable_engine_required).and_return(true)
        controller.stub(:admin_required).and_return(true)
        @routes.draw do
          resources :anonymous do
            member do
              get :show_file
            end
          end
        end
        @advertisement = create(:advertisement1)
      end

      shared_examples_for "インスタンス変数@advertisementが正しく設定されているかの検証" do
        it "インスタンス変数@advertisementがAdvertisementクラスのインスタンスであること" do
          assigns[:advertisement].should be_kind_of(Advertisement)
        end

        it "インスタンス変数@advertisementのidがパラメータ:idで送った値と等しいこと" do
          (assigns[:advertisement].id == @advertisement.id).should be true
        end
      end

      context "GET showにアクセスしたとき" do
        before do
          get :show, id: @advertisement.id, use_route: :advertisement_management
        end
        it_behaves_like "インスタンス変数@advertisementが正しく設定されているかの検証"
      end

      context "GET editにアクセスしたとき" do
        before do
          get :edit, id: @advertisement.id, use_route: :advertisement_management
        end
        it_behaves_like "インスタンス変数@advertisementが正しく設定されているかの検証"
      end

      context "PATCH updateにアクセスしたとき" do
        before do
          patch :update, id: @advertisement.id, use_route: :advertisement_management
        end
        it_behaves_like "インスタンス変数@advertisementが正しく設定されているかの検証"
      end

      context "GET show_fileにアクセスしたとき" do
        before do
          get :show_file, id: @advertisement.id, use_route: :advertisement_management
        end
        it_behaves_like "インスタンス変数@advertisementが正しく設定されているかの検証"
      end

      context "DELETE destroyにアクセスしたとき" do
        before do
          delete :destroy, id: @advertisement.id, use_route: :advertisement_management
        end
        it_behaves_like "インスタンス変数@advertisementが正しく設定されているかの検証"
      end
    end
  end

  describe "アクション" do
    # NOTE: redirect先が Engine でなくなるため
    routes { AdvertisementManagement::Engine.routes }

    before do
      controller.stub(:enable_engine_required).and_return(true)
      controller.stub(:admin_required).and_return(true)
    end

    describe "GET index" do
      describe "正常系" do
        before do
          2.times do
            Advertisement::STATE.each do |k, v|
              create(:pref_advertisement, state: k)
              create(:corp_advertisement, state: k)
            end
          end
        end

        subject{get :index}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "indexをrenderしていること" do
          expect(subject).to render_template("index")
        end

        context "インスタンス変数@pref_adsにセットされている値の取得条件" do
          it "Advertisementオブジェクトが取得できていること" do
            subject
            expect(assigns[:pref_ads].first).to be_kind_of(Advertisement)
          end

          it "side_type=INSIDE_TYPE(1)のものが取得されていること" do
            subject
            expect(assigns[:pref_ads].all?{|a|a.side_type == Advertisement::INSIDE_TYPE}).to be true
          end

          it "並び順がstate DESC, pref_ad_numberの順になっていること" do
            subject
            lists = assigns[:pref_ads].sort{|a, b|[b.state, a.pref_ad_number] <=> [a.state, b.pref_ad_number]}
            expect(assigns[:pref_ads].to_a).to eq(lists)
          end
        end

        context "インスタンス変数@corp_adsにセットされている値の取得条件" do
          it "Advertisementオブジェクトが取得できていること" do
            subject
            expect(assigns[:corp_ads].first).to be_kind_of(Advertisement)
          end

          it "side_type=OUTSIDE_TYPE(2)のものが取得されていること" do
            subject
            expect(assigns[:corp_ads].all?{|a|a.side_type == Advertisement::OUTSIDE_TYPE}).to be true
          end

          it "並び順がstate DESC, corp_ad_numberの順になっていること" do
            subject
            lists = assigns[:corp_ads].sort{|a, b|[b.state, a.corp_ad_number] <=> [a.state, b.corp_ad_number]}
            expect(assigns[:corp_ads].to_a).to eq(lists)
          end
        end
      end
    end

    describe "GET show" do
      let!(:advertisement) { create(:advertisement1) }

      describe "正常系" do
        subject{get :show, id: advertisement.id}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "indexをrenderしていること" do
          expect(subject).to render_template("show")
        end

        it "advertisementオブジェクトが取得できていること" do
          subject
          expect(assigns[:advertisement]).to be_a(Advertisement)
        end

        it "advertisementオブジェクトが存在するレコードインスタンスであること" do
          subject
          expect(assigns[:advertisement].new_record?).to be false
        end
      end
    end

    describe "GET new" do
      describe "正常系" do
        subject{get :new}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "indexをrenderしていること" do
          expect(subject).to render_template("new")
        end

        it "advertisementオブジェクトが取得できていること" do
          subject
          expect(assigns[:advertisement]).to be_a(Advertisement)
        end

        it "advertisementオブジェクトが新規インスタンスであること" do
          subject
          expect(assigns[:advertisement].new_record?).to be true
        end
      end
    end

    describe "GET edit" do
      let!(:advertisement) { create(:advertisement1) }

      describe "正常系" do
        subject{get :edit, id: advertisement.id}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "indexをrenderしていること" do
          expect(subject).to render_template("edit")
        end

        it "advertisementオブジェクトが取得できていること" do
          subject
          expect(assigns[:advertisement]).to be_a(Advertisement)
        end

        it "advertisementオブジェクトが存在するレコードインスタンスであること" do
          subject
          expect(assigns[:advertisement].new_record?).to be false
        end
      end
    end

    describe "POST create" do
      describe "正常系" do
        subject{post :create, advertisement_params}

        it "Advertisementテーブルにレコードが１件追加されていること" do
          expect{subject}.to change(Advertisement, :count).by(1)
        end

        it "画像ファイルがアップされていること" do
          subject
          ad = Advertisement.last
          file_name = "#{ad.id}#{File.extname(ad.image_file_name)}"
          path = File.join(Rails.root, Advertisement::IMAGE_DIR, file_name)
          expect(File.exists?(path)).to be true
        end

        it "広告一覧にリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_advertisements_path)
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            Advertisement.any_instance.stub(:save).and_return(false)
          end

          subject{post :create, advertisement_params}

          it "再度作成画面が描画されること" do
            expect(subject).to render_template("new")
          end

          it "レコードが追加されていないこと" do
            expect{subject}.to change(Advertisement, :count).by(0)
          end
        end

        context "パラメータ:advertisementにstateがセットされた場合" do
          subject{post :create, advertisement_params(advertisement: {state: 2})}

          it "state項目に値がセットされないこと" do
            subject
            expect(Advertisement.last.state).to eq(2)
          end
        end
      end
    end

    describe "PATCH update" do
      before do
        @advertisement = create(:advertisement1)
        id = @advertisement.id
        controller.instance_eval do
          @advertisement = Advertisement.find(id)
        end
      end

      describe "正常系" do
        subject{patch :update, advertisement_params(id: @advertisement.id)}

        it "部局一覧にリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_advertisements_path)
        end

      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            Advertisement.any_instance.stub(:save).and_return(false)
          end

          subject{patch :update, advertisement_params(id: @advertisement.id)}

          it "再度編集画面が描画されること" do
            expect(subject).to render_template("edit")
          end
        end

        context "パラメータ:advertisementにstateがセットされた場合" do
          subject{patch :update, advertisement_params(id: @advertisement.id, advertisement: {state: 2})}

          it "state項目に値がセットされないこと" do
            subject
            expect(Advertisement.last.state).to eq(2)
          end
        end
      end
    end

    describe "DELETE destroy" do
      before do
        @advertisement = create(:advertisement1)
        id = @advertisement.id
        controller.stub(:set_advertisement).and_return(true)
        controller.instance_eval do
          @advertisement = Advertisement.find(id)
        end
      end

      subject{delete :destroy, id: @advertisement.id}

      describe "正常系" do
        it "部局一覧にリダイレクトすること" do

          expect(subject).to redirect_to(susanoo_advertisements_path)
        end

        it "Advertisementテーブルのレコードが１件削除されていること" do
          expect{subject}.to change(Advertisement, :count).by(-1)
        end

        it "params[:id]で渡したIDのレコードがテーブルから削除されていること" do
          expect{subject}.to change{Advertisement.exists?(@advertisement.id)}.by(false)
        end
      end
    end

    describe "GET show_file" do
      before do
        @advertisement = create(:advertisement1)
        id = @advertisement.id
        controller.instance_eval do
          @advertisement = Advertisement.find(id)
        end
      end

      describe "正常系" do
        subject{get :show_file, id: @advertisement}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "advertisementオブジェクトが取得できていること" do
          subject
          expect(assigns[:advertisement]).to be_a(Advertisement)
        end

        it "advertisementオブジェクトが存在するレコードインスタンスであること" do
          subject
          expect(assigns[:advertisement].new_record?).to be false
        end

        it "表示するファイルが正しいこと" do
          expect(subject.body.force_encoding("utf-8")).to eq(IO.read(@advertisement.image.path))
        end
      end
    end

    describe "GET edit_state" do
      describe "正常系" do
        before do
          2.times do
            Advertisement::STATE.each do |k, v|
              create(:pref_advertisement, state: k)
              create(:corp_advertisement, state: k)
              create(:toppage_advertisement, state: k)
            end
          end
        end

        subject{get :edit_state}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "edit_stateがrenderされること" do
          expect(subject).to render_template("edit_state")
        end

        context "インスタンス変数@pref_adsにセットされている値の取得条件" do
          before do
            subject
          end

          it "Advertisementオブジェクトが取得できていること" do
            expect(assigns[:pref_ads].first).to be_kind_of(Advertisement)
          end

          it "side_type=INSIDE_TYPE(1)のものが取得されていること" do
            expect(assigns[:pref_ads].all?{|a|a.side_type == Advertisement::INSIDE_TYPE}).to be true
          end

          it "並び順がstate DESC, pref_ad_numberの順になっていること" do
            lists = assigns[:pref_ads].sort{|a, b|[b.state, a.pref_ad_number] <=> [a.state, b.pref_ad_number]}
            expect(assigns[:pref_ads].to_a).to eq(lists)
          end
        end

        context "インスタンス変数@corp_adsにセットされている値の取得条件" do
          before do
            subject
          end

          it "Advertisementオブジェクトが取得できていること" do
            expect(assigns[:corp_ads].first).to be_kind_of(Advertisement)
          end

          it "side_type=OUTSIDE_TYPE(2)のものが取得されていること" do
            expect(assigns[:corp_ads].all?{|a|a.side_type == Advertisement::OUTSIDE_TYPE}).to be true
          end

          it "並び順がstate DESC, corp_ad_numberの順になっていること" do
            lists = assigns[:corp_ads].sort{|a, b|[b.state, a.corp_ad_number] <=> [a.state, b.corp_ad_number]}
            expect(assigns[:corp_ads].to_a).to eq(lists)
          end
        end

        context "Advertisementに対してAdvertisementListの再設定" do
          it "全てのAdvertisementにAdvertisementListレコードが設定されるか？" do
            subject
            expect(Advertisement.all.all?{|a|a.advertisement_list.class == AdvertisementList}).to be true
          end
        end
      end

      describe "異常系" do
        subject{get :edit_state}

        it "例外が発生した場合、広告管理画面にリダイレクトすること" do
          Advertisement.stub(:resetting_list).and_raise
          expect(subject).to redirect_to(susanoo_advertisements_path)
        end
      end
    end

    describe "POST update_state" do
      before do
        @params = {}
        %i(pref_advertisement_list corp_advertisement_list toppage_advertisement_list).each do |factory|
          Advertisement::STATE.keys.each do |state|
            (1..2).each do |n|
              al = create(factory)
              @params[al.advertisement_id] = state
            end
          end
        end.flatten
      end

      describe "正常系" do
        context "「順番設定画面に進む」ボタンを押した場合" do
          subject{post :update_state, advertisement: @params}

          it "params[:advertisement]にセットされた値で更新がかかること" do
            subject
            flg = @params.all? do |id, state|
                    ad = Advertisement.find(id)
                    ad.advertisement_list.state == state
                  end
            expect(flg).to be true
          end

          it "順番設定画面にリダイレクトすること" do
            expect(subject).to redirect_to(sort_susanoo_advertisements_path)
          end
        end

        context "params[:cancel]が送られた場合" do
          subject{post :update_state, cancel: true}

          it "AdvertisementListレコードが全件削除されこと" do
            3.times{create(:advertisement_list1)}
            count = AdvertisementList.count
            expect{subject}.to change{AdvertisementList.count}.by(-count)
          end

          it "広告管理画面にリダイレクトされること" do
            expect(subject).to redirect_to(susanoo_advertisements_path)
          end
        end
      end

      describe "異常系" do
        context "例外が発生した場合" do
          subject{post :update_state, advertisement: @params}

          it "公開設定画面にリダイレクトすること" do
            AdvertisementList.any_instance.stub(:save!).and_raise
            expect(subject).to redirect_to(edit_state_susanoo_advertisements_path)
          end
        end
      end
     end

    describe "GET sort" do
      before do
        2.times do
          create(:pref_advertisement_list, state: Advertisement::PUBLISHED)
          create(:corp_advertisement_list, state: Advertisement::PUBLISHED)
          create(:published_toppage_advertisement_list)
        end
      end

      describe "正常系" do
        subject{get :sort}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "sortがrenderされること" do
          expect(subject).to render_template("sort")
        end

        context "インスタンス変数@pref_adsにセットされている値の取得条件" do
          before{subject}

          it "AdvertisementListオブジェクトが取得できていること" do
            expect(assigns[:pref_ads].first).to be_kind_of(AdvertisementList)
          end

          it "side_type=INSIDE_TYPE(1)のものが取得されていること" do
            flg = assigns[:pref_ads].all?{|a|a.advertisement.side_type == Advertisement::INSIDE_TYPE}
            expect(flg).to be true
          end

          it "state=PUBLISHED(2)のものが取得されていること" do
            flg = assigns[:pref_ads].all?{|a|a.state == Advertisement::PUBLISHED}
            expect(flg).to be true
          end

          it "並び順がpref_ad_numberの順になっていること" do
            lists = assigns[:pref_ads].sort{|a, b|a.pref_ad_number <=> b.pref_ad_number}
            expect(assigns[:pref_ads].to_a).to eq(lists)
          end

          it "取得された@pref_adsのpref_ad_numberが連番になっていること" do
            flg = assigns[:pref_ads].map.with_index do |ads, i|
                    ads.pref_ad_number == i
                  end.all?
            expect(flg).to be true
          end
        end

        context "インスタンス変数@corp_adsにセットされている値の取得条件" do
          before{subject}

          it "AdvertisementListオブジェクトが取得できていること" do
            expect(assigns[:corp_ads].first).to be_kind_of(AdvertisementList)
          end

          it "side_type=OUTSIDE_TYPE(2)のものが取得されていること" do
            flg = assigns[:corp_ads].all?{|a|a.advertisement.side_type == Advertisement::OUTSIDE_TYPE}
            expect(flg).to be true
          end

          it "state=PUBLISHED(2)のものが取得されていること" do
            flg = assigns[:corp_ads].all?{|a|a.state == Advertisement::PUBLISHED}
            expect(flg).to be true
          end

          it "並び順がcorp_ad_numberの順になっていること" do
            lists = assigns[:corp_ads].sort{|a, b|a.corp_ad_number <=> b.corp_ad_number}
            expect(assigns[:corp_ads].to_a).to eq(lists)
          end

          it "取得された@corp_adsのcorp_ad_numberが連番になっていること" do
            flg = assigns[:corp_ads].map.with_index do |ads, i|
                    ads.corp_ad_number == i
                  end.all?
            expect(flg).to be true
          end
        end
      end
    end

    describe "POST update_sort" do
      before do
        2.times do
          create(:pref_advertisement_list, state: Advertisement::PUBLISHED)
          create(:corp_advertisement_list, state: Advertisement::PUBLISHED)
          create(:published_toppage_advertisement_list)
        end
      end

      describe "正常系" do
        let(:inside){Advertisement::SIDE_TYPE[Advertisement::INSIDE_TYPE]}

        subject{post :update_sort, side_type: inside}

        it "レスポンスが200であること" do
          expect(subject).to be_success
        end

        it "sortが描画されること" do
          expect(subject).to render_template("sort")
        end

        context "params[:side_type]に'pref'が送られた場合" do
          let(:inside){Advertisement::SIDE_TYPE[Advertisement::INSIDE_TYPE]}
          let(:ids){AdvertisementList.order("pref_ad_number desc").map(&:id)}

          subject{post :update_sort, side_type: inside, item: ids}

          it "params[:item]に送られたIDの順でpref_ad_numberが設定されること" do
            subject
            expect(AdvertisementList.order("pref_ad_number").map(&:id)).to eq(ids)
          end

          it "params[:item]に送られたIDの順で@pref_adsが設定されること" do
            subject
            expect(assigns[:pref_ads].map(&:id)).to eq(ids)
          end

          context "インスタンス変数@corp_adsの取得条件" do
            let(:inside){Advertisement::SIDE_TYPE[Advertisement::INSIDE_TYPE]}
            let(:ids){AdvertisementList.order("pref_ad_number desc").map(&:id)}

            subject{post :update_sort, side_type: inside, item: ids}
            before{subject}

            it "AdvertisementListオブジェクトが取得できていること" do
              expect(assigns[:corp_ads].first).to be_kind_of(AdvertisementList)
            end

            it "side_type=OUTSIDE_TYPE(2)のものが取得されていること" do
              flg = assigns[:corp_ads].all?{|a|a.advertisement.side_type == Advertisement::OUTSIDE_TYPE}
              expect(flg).to be true
            end

            it "state=PUBLISHED(2)のものが取得されていること" do
              flg = assigns[:corp_ads].all?{|a|a.state == Advertisement::PUBLISHED}
              expect(flg).to be true
            end

            it "並び順がcorp_ad_numberの順になっていること" do
              lists = assigns[:corp_ads].sort{|a, b|a.corp_ad_number <=> b.corp_ad_number}
              expect(assigns[:corp_ads].to_a).to eq(lists)
            end
          end
        end

        context "params[:side_type]に'corp'が送られた場合" do
          let(:outside){Advertisement::SIDE_TYPE[Advertisement::OUTSIDE_TYPE]}
          let(:ids){AdvertisementList.order("corp_ad_number desc").map(&:id)}

          subject{post :update_sort, side_type: outside, item: ids}
          before{subject}

          it "params[:item]に送られたIDの順でcorp_ad_numberが設定されること" do
            expect(AdvertisementList.order("corp_ad_number").map(&:id)).to eq(ids)
          end

          it "params[:item]に送られたIDの順で@corp_adsが設定されること" do
            expect(assigns[:corp_ads].map(&:id)).to eq(ids)
          end

          context "インスタンス変数@pref_adsの取得条件" do
            let(:outside){Advertisement::SIDE_TYPE[Advertisement::OUTSIDE_TYPE]}
            let(:ids){AdvertisementList.order("corp_ad_number desc").map(&:id)}

            subject{post :update_sort, side_type: outside, item: ids}
            before{subject}

            it "AdvertisementListオブジェクトが取得できていること" do
              expect(assigns[:pref_ads].first).to be_kind_of(AdvertisementList)
            end

            it "side_type=INTSIDE_TYPE(1)のものが取得されていること" do
              flg = assigns[:pref_ads].all?{|a|a.advertisement.side_type == Advertisement::INSIDE_TYPE}
              expect(flg).to be true
            end

            it "state=PUBLISHED(2)のものが取得されていること" do
              flg = assigns[:pref_ads].all?{|a|a.state == Advertisement::PUBLISHED}
              expect(flg).to be true
            end

            it "並び順がcorp_ad_numberの順になっていること" do
              lists = assigns[:pref_ads].sort{|a, b|a.pref_ad_number <=> b.pref_ad_number}
              expect(assigns[:pref_ads].to_a).to eq(lists)
            end
          end
        end
      end
    end

    describe "POST finish_sort" do
      before do
        2.times do
          create(:pref_advertisement_list, state: Advertisement::PUBLISHED)
          create(:corp_advertisement_list, state: Advertisement::PUBLISHED)
          create(:published_toppage_advertisement_list)
        end
      end

      describe "正常系" do
        context "params[:save]が送られた場合" do
          subject{post :finish_sort, save: true }

          it "広告管理画面にリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_advertisements_path)
          end

          it "Jobに１件レコードが追加されること" do
            expect{subject}.to change(Job, :count).by(1)
          end

          it "action='move_banner_images',datetime=Time.nowのレコードが追加されること" do
            now = Time.local(2013, 12, 1, 10, 0, 0)
            Time.stub(:now).and_return(now)
            subject
            j = Job.last
            (j.action == 'move_banner_images' && j.datetime == now).should be true
          end
        end

        context "params[:cancel]が送られた場合" do
          subject{post :finish_sort, cancel: true }

          it "広告管理画面にリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_advertisements_path)
          end

          it "AdvertisementListが全件削除されること" do
            count = AdvertisementList.count
            expect{subject}.to change(AdvertisementList, :count).by(-count)
          end
        end
      end

      describe "異常系" do
        subject{post :finish_sort, save: true }

        it "例外が発生した場合広告管理トップへリダイレクトすること" do
          Job.stub(:create).and_raise
          expect(subject).to redirect_to(susanoo_advertisements_path)
        end
      end
    end
  end

  describe "private" do
    describe "set_advertisement" do
      let(:id){create(:advertisement1).id}
      before{controller.params[:id] = id}
      subject{controller.send(:set_advertisement)}

      it "params[:id]のAdvertisementレコードが取得されること" do
        subject
        expect(assigns[:advertisement]).to eq(Advertisement.find(id))
      end
    end
    describe "advertisement_params" do
      let(:valid_params){
        {
          image: fixture_file_upload(
            File.join(File.dirname(__FILE__), '../..', "files/rails.png"),
            'image/png'
          ),
          name: "test_name",
          alt: "test_alt",
          url: "http://localhost:3000",
          begin_date: DateTime.now,
          end_date: (DateTime.now + 1),
          side_type: Advertisement::INSIDE_TYPE,
          show_in_header: true,
          description: "test_description",
          description_link: "test_description_link"
        }
      }
      let(:invalid_params){valid_params.merge(pref_ad_number: 1)}
      subject{controller.send(:advertisement_params)}
      before{controller.params[:advertisement] = invalid_params}

      it ":pref_ad_numberが外されること" do
        expect(subject).to eq(valid_params.stringify_keys)
      end
    end
  end

  after(:all) do
    dir = File.join(Rails.root, ::Advertisement::IMAGE_DIR)
    FileUtils.rm(Dir.glob(dir + "/*.png")) if File.exists? dir
  end
end

def advertisement_params(attr = {})
  ad_attr = attr.delete(:advertisement)
  at = {
    advertisement: {
      image: fixture_file_upload(
        File.join(File.dirname(__FILE__), '../..', "files/rails.png"),
        'image/png'
      ),
      name: "test_name",
      alt: "test_alt",
      url: "http://localhost:3000",
      begin_date: DateTime.now,
      end_date: (DateTime.now + 1),
      side_type: Advertisement::INSIDE_TYPE,
      show_in_header: true,
      description: "test_description",
      description_link: "test_description_link"

    }.merge(ad_attr || {})
  }.merge(attr || {})
  at.merge(use_route: :advertisement_management)
end
