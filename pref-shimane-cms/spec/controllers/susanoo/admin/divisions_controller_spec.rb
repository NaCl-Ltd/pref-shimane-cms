require 'spec_helper'

describe Susanoo::Admin::DivisionsController do
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
        %w(index new create edit update destroy update_sort).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:set_division).and_return(true)
        @routes.draw do
          resources :anonymous do
            collection do
              post :update_sort
            end
          end
        end
        @division = create(:division)
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index)         {before{get :index}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :new)           {before{get :new}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :create)       {before{post :create}}
        it_behaves_like("未ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @division.id}}
        it_behaves_like("未ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @division.id}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @division.id}}
        it_behaves_like("未ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
      end

      context "ログイン状態" do
        context "運用管理者の場合" do
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :new)           {before{get :new}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :create)       {before{post :create}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @division.id}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @division.id}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @division.id}}
          it_behaves_like("運用管理者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
        end

        context "情報提供責任者の場合" do
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :new)           {before{get :new}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :create)       {before{post :create}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @division.id}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @division.id}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @division.id}}
          it_behaves_like("情報提供責任者ログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
        end

        context "一般ユーザの場合" do
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :index)         {before{get :index}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :new)           {before{get :new}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :create)       {before{post :create}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :get, :edit)          {before{get :edit, id: @division.id}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :patch, :update)      {before{patch :update, id: @division.id}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :delete, :destroy)    {before{delete :destroy, id: @division.id}}
          it_behaves_like("一般ユーザログイン時のアクセス制限", :post, :update_sort)  {before{post :update_sort}}
        end
      end
    end

    describe "set_division" do
      controller do
        %w(edit update destroy).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:admin_required).and_return(true)
        @routes.draw do
          resources :anonymous
        end

        @genre_1 = create(:genre, path: "/", section_id: 10)

        @division = create(:division)
      end

      shared_examples_for "インスタンス変数@divisionが正しく設定されているかの検証" do
        it "インスタンス変数@divisionがDivisionクラスのインスタンスであること" do
          assigns[:division].should be_kind_of(Division)
        end

        it "インスタンス変数@divisionのidがパラメータ:idで送った値と等しいこと" do
          (assigns[:division].id == @division.id).should be_true
        end
      end

      context "GET editにアクセスしたとき" do
        before do
          get :edit, id: @division.id
        end
        it_behaves_like "インスタンス変数@divisionが正しく設定されているかの検証"
      end

      context "PATCH updateにアクセスしたとき" do
        before do
          patch :update, id: @division.id
        end
        it_behaves_like "インスタンス変数@divisionが正しく設定されているかの検証"
      end

      context "DELETE destroyにアクセスしたとき" do
        before do
          delete :destroy, id: @division.id
        end
        it_behaves_like "インスタンス変数@divisionが正しく設定されているかの検証"
      end
    end
  end

  describe "アクション" do
    describe "GET index" do
      before do
        controller.stub(:admin_required).and_return(true)
      end

      describe "正常系" do
        subject {get :index}

        it "indexをrenderしていること" do
          expect(subject).to render_template(:index)
        end

        it "divisionがnumber順に全件取得できていること" do
          subject
          lists = Division.order("number")
          expect(assigns[:divisions]).to eq(lists)
        end
      end
    end

    describe "GET new" do
      before do
        controller.stub(:admin_required).and_return(true)
      end

      describe "正常系" do
        subject {get :new}

        it "newをrenderしていること" do
          expect(subject).to render_template(:new)
        end

        it "divisionオブジェクトが取得できていること" do
          subject
          expect(assigns[:division]).to be_a(Division)
        end

        it "divisionオブジェクトが新規インスタンスであること" do
          subject
          expect(assigns[:division].new_record?).to be_true
        end
      end
    end

    describe "GET edit" do
      before do
        @division = create(:division)
        id = @division.id
        controller.stub(:admin_required).and_return(true)
        controller.stub(:set_division).and_return(true)
        controller.instance_eval do
          @division = Division.find(id)
        end
      end

      describe "正常系" do
        subject{get :edit, id: @division.id}

        it "editをrenderしていること" do
          expect(subject).to render_template(:edit)
        end

        it "divisionオブジェクトが取得できていること" do
          subject
          expect(assigns[:division]).to be_a(Division)
        end

        it "divisionオブジェクトが存在するレコードインスタンスであること" do
          subject
          expect(assigns[:division].new_record?).to be_false
        end
      end
    end

    describe "POST create" do
      before do
        controller.stub(:admin_required).and_return(true)
      end

      describe "正常系" do
        subject{post :create, division_params}

        it "部局一覧にリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_admin_divisions_path)
        end

        it "部局テーブルにレコードが１件追加されていること" do
          expect{subject}.to change(Division, :count).by(1)
        end

        it "新たに追加された部局が、既存の部局のnumber+1の値がnumberに設定されていること" do
          division = create(:division)
          add_number = Division.maximum(:number) + 1
          subject
          expect(Division.maximum(:number)).to eq(add_number)
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          subject{post :create, division_params(division: {name: nil})}

          it "newがrenderされること" do
            expect(subject).to render_template("new")
          end

          it "レコードが追加されていないこと" do
            expect{subject}.to change(Division, :count).by(0)
          end
        end

        context "パラメータ:divisionにnumberがセットされた場合" do
          let(:number){50000}
          subject{post :create, division_params(division: {number: number})}

          it "number項目に値がセットされないこと" do
            expect(Division.maximum(:number)).to_not eq(number)
          end
        end
      end
    end

    describe "PATCH update" do
      before do
        @division = create(:division)
        id = @division.id
        controller.stub(:admin_required).and_return(true)
        controller.stub(:set_division).and_return(true)
        controller.instance_eval do
          @division = Division.find(id)
        end
      end

      describe "正常系" do
        context "バリデーションに成功した場合" do
          before do
            Division.any_instance.stub(:invalid?).and_return(false)
          end

          subject{patch :update, division_params(id: @division.id)}

          context "保存に成功した場合" do
            it "一覧画面にリダイレクトすること" do
              Division.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(susanoo_admin_divisions_path)
            end
          end

          context "保存に失敗した場合" do
            it "再度編集画面を描画していること" do
              Division.any_instance.stub(:save).and_return(false)
              patch :update, division_params(id: @division.id)
              expect(subject).to render_template(:edit)
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do

          subject{patch :update, division_params(id: @division.id, division: {name: nil})}

          it "再度編集画面が描画されること" do
            expect(subject).to render_template("edit")
          end
        end

        context "パラメータ:divisionにnumberがセットされた場合" do
          let(:number){50000}
          subject{patch :update, division_params(id: @division.id, division: {number: number})}

          it "number項目に値がセットされないこと" do
            subject
            expect(Division.maximum(:number)).to_not eq(number)
          end
        end
      end
    end

    describe "DELETE destroy" do
      before do
        @division = create(:division)
        id = @division.id
        controller.stub(:admin_required).and_return(true)
        controller.stub(:set_division).and_return(true)
        controller.instance_eval do
          @division = Division.find(id)
        end
      end

      describe "正常系" do
        let(:user) { create(:user) }

        subject{delete :destroy, id: @division.id}

        before { login(user) }

        it "部局一覧にリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_admin_divisions_path)
        end

        it "Divisionテーブルのレコードが１件削除されていること" do
          expect{subject}.to change(Division, :count).by(-1)
        end

        it "params[:id]で渡したIDのレコードがテーブルから削除されていること" do
          expect{subject}.to change{Division.exists?(@division.id)}.by(false)
        end
      end
    end

    describe "POST update_sort" do
      before do
        controller.stub(:admin_required).and_return(true)
        @divisions = (1..3).to_a.map{|a|create(:division)}
      end

      describe "正常系" do
        subject{post :update_sort, item: @divisions.map(&:id)}

        it "sortをrenderしていること" do
          expect(subject).to render_template(:_sort)
        end

        it "送られたIDの順に並び替えられていること" do
          send_ids = @divisions.sort_by(&:number).map(&:id).reverse
          post :update_sort, item: send_ids
          expect(Division.order("number").map(&:id)).to eq(send_ids)
        end
      end

      describe "異常系" do
        subject{post :update_sort, item: @divisions.map(&:id)}

        context "更新処理に失敗した場合" do
          before{Division.any_instance.stub(:update!).and_raise}

          it "@divisionsが[]になること" do
            subject
            expect(assigns[:divisions]).to be_empty
          end

          it "sortをrenderしていること" do
            expect(subject).to render_template(:_sort)
          end
        end
      end
    end
  end
end

def division_params(attr = {})
  division_attr = attr.delete(:division)
  {
    division: {
      name: "テスト",
    }.merge(division_attr || {})
  }.merge(attr || {})
end
