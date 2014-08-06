require 'spec_helper'

describe Susanoo::Admin::HelpCategoriesController do
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

  describe "フィルタ" do
    controller do
      %w(index treeview edit new create update destroy update_sort help_list change_navigation).each do |method|
        define_method(method) do
          render text: :OK
        end
      end
    end

    before do
      @routes.draw do
        resources :anonymous, except: [:show] do
          collection do
            get :treeview
            post :update_sort
            get :help_list
          end

          member do
            get :change_navigation
          end
        end
      end
    end

    describe "admin_required" do
      context "未ログイン状態の場合" do
        shared_example_name = "未ログイン時のアクセス制限"

        it_should_behave_like(shared_example_name, :index) { before {get :index } }
        it_should_behave_like(shared_example_name, :new) { before {get :new } }
        it_should_behave_like(shared_example_name, :crate) { before {post :create } }
        it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
        it_should_behave_like(shared_example_name, :destroy) { before {delete :destroy, id: 1 } }
        it_should_behave_like(shared_example_name, :treeview) { before {get :treeview } }
        it_should_behave_like(shared_example_name, :update_sort) { before {post :update_sort } }
        it_should_behave_like(shared_example_name, :help_list) { before {get :help_list } }
        it_should_behave_like(shared_example_name, :change_navigation) { before {get :change_navigation, id: 1 } }
      end

      context "ログイン状態の場合" do
        context "情報提供責任者の場合" do
          shared_example_name = "情報提供責任者ログイン時のアクセス制限"

          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :new) { before {get :new } }
          it_should_behave_like(shared_example_name, :crate) { before {post :create } }
          it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
          it_should_behave_like(shared_example_name, :destroy) { before {delete :destroy, id: 1 } }
          it_should_behave_like(shared_example_name, :treeview) { before {get :treeview } }
          it_should_behave_like(shared_example_name, :update_sort) { before {post :update_sort } }
          it_should_behave_like(shared_example_name, :help_list) { before {get :help_list } }
          it_should_behave_like(shared_example_name, :change_navigation) { before {get :change_navigation, id: 1 } }
        end

        context "一般ユーザの場合" do
          shared_example_name = "一般ユーザログイン時のアクセス制限"

          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :new) { before {get :new } }
          it_should_behave_like(shared_example_name, :crate) { before {post :create } }
          it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
          it_should_behave_like(shared_example_name, :destroy) { before {delete :destroy, id: 1 } }
          it_should_behave_like(shared_example_name, :treeview) { before {get :treeview } }
          it_should_behave_like(shared_example_name, :update_sort) { before {post :update_sort } }
          it_should_behave_like(shared_example_name, :help_list) { before {get :help_list } }
          it_should_behave_like(shared_example_name, :change_navigation) { before {get :change_navigation, id: 1 } }
        end
      end
    end
  end

  describe "アクション" do
    before do
      login(create(:user))
    end

    describe "GET index" do

      subject{ get :index }

      describe "正常系" do
        it "indexをrenderしていること" do
          expect(subject).to render_template(:index)
        end
      end
    end


    describe "GET treeview" do

      subject{ get :treeview }

      describe "正常系" do
        it "HelpCategoryにsiblings_for_treeviewを呼び出していること" do
          HelpCategory.should_receive(:siblings_for_treeview)
          subject
        end
      end
    end

    describe "GET new" do
      subject{ get :new }

      describe "正常系" do
        it "新しいHelpレコードを作成していること" do
          subject
          expect(assigns[:child_help_category].new_record?).to be_true
        end

        it "new_dialogをrenderしていること" do
          expect(subject).to render_template(:new)
        end

        context "parent_idが存在する場合" do
          let(:parent_id) { 1 }

          subject{ get :new, parent_id: parent_id }

          before do
            @parent_help_category = create(:help_category, id: parent_id, name: 'name')
          end

          it "parent_idをセットしていること" do
            subject
            expect(assigns[:child_help_category].parent_id).to eq(parent_id)
          end

          it "親レコードを取得していること" do
            subject
            expect(assigns[:parent_help_category]).to eq(@parent_help_category)
          end
        end
      end
    end

    describe "POST create" do
      subject { xhr :post, :create, {help_category: {name: 'name'}} }

      describe "正常系" do
        context "バリデーションに成功した場合" do
          it "HelpCategoryが追加されること" do
            old_count = HelpCategory.count
            expect{ subject }.to change { HelpCategory.count }.from(old_count).to(old_count + 1)
          end
        end
      end
    end

    describe "PATCH update" do
      subject { xhr :post, :update, {id: @help_category.id, help_category: @help_category.attributes} }

      describe "正常系" do
        let(:number) { 0 }

        before do
          @help_category = create(:help_category, name: 'name', number: number)
        end

        context "バリデーションに成功した場合" do
          before :each do
            HelpCategory.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "numberに最大値が設定されていること" do
              subject
              expect(assigns[:help_category].number).to eq(number)
            end
          end
        end
      end

      describe "異常系" do
        let(:number) { 0 }

        before do
          @help_category = create(:help_category, name: 'name', number: number)
        end

        subject { xhr :post, :update, {id: @help_category.id, help_category: @help_category.attributes}}

        context "バリデーションに失敗した場合" do
          before :each do
            HelpCategory.any_instance.stub(:save).and_return(false)
          end
        end

        context "更新できない項目のパラメータがセットされている場合" do
          subject {xhr :post, :update, id: @help_category.id, help_category: @help_category.attributes.merge(number: 100)}

          it "値が更新されていないこと" do
            subject
            expect(@help_category.reload.number).to eq(number)
          end
        end
      end
    end

    describe "DELETE destroy" do
      describe "正常系" do
        before do
          @help_category = create(:help_category, name: 'title')
        end

        subject { delete :destroy, id: @help_category.id, format: 'js' }

        it "HelpCategoryの数が減っていること" do
          old_count = HelpCategory.count
          expect{subject}.to change {HelpCategory.count}.from(old_count).to(old_count - 1)
        end
      end
    end

    describe "POST update_sort" do
      describe "正常系" do
        context "params[:help_categories]が存在しない場合" do
          before do
            @help_category = create(:help_category, name: 'name')
          end

          subject{post :update_sort, id: @help_category.id}

          it "change_parent!メソッドが呼び出されていること" do
            HelpCategory.any_instance.should_receive(:change_parent!)
            subject
          end

          it "alertをrenderしていること" do
            expect(subject).to render_template("shared/help_categories/_alert")
          end
        end

        context "params[:help_categories]が存在する場合" do
          let(:parent_id){ 1 }

          before do
            @help_categories = {}
            3.times{|i|
              h_c = create(:help_category, name: 'name', number: i)
              @help_categories[i + 1] = {id: h_c.id}
            }
          end

          subject { post :update_sort, parent_id: parent_id, help_categories: @help_categories }

          it "並び替えの更新が行われていること" do
            subject
            h_cs = HelpCategory.all
            h_cs.each.with_index(1) do |h_c, number|
              expect(h_c.parent_id).to eq(parent_id)
              expect(h_c.number).to eq(number)
            end
          end
        end
      end

      describe "異常系" do
        context "保存時に例外が発生した場合" do
          before do
            @help_category = create(:help_category, name: 'name')
          end

          subject{post :update_sort, id: @help_category.id}

          it "alertをrenderしていること" do
            HelpCategory.any_instance.stub(:change_parent!).and_raise(StandardError)
            expect(subject).to render_template("shared/help_categories/_alert")
          end
        end
      end
    end

    describe "GET help_list" do
      context "正常系" do
        let(:help_category_id) { 1 }

        subject { get :help_list, help_category_id: help_category_id}

        before do
          create(:help, name: 'name', help_category_id: help_category_id)
        end

        it "parent_idが一致するものを取り出していること" do
          subject
          expect(assigns[:helps].all?{|h| h.help_category_id == help_category_id}).to be_true
        end
      end
    end

    describe "GET change_navigation" do
      describe "正常系" do
        subject { get :change_navigation, id: @help_category.id }

        it "ヘルプカテゴリ一覧画面へリダイレクトすること" do
          @help_category = create(:help_category, navigation: false)
          expect(subject).to redirect_to(susanoo_admin_help_categories_path)
        end

        context "falseの場合" do
          before do
            @help_category = create(:help_category, navigation: false)
          end

          it "trueにすること" do
            subject
            expect(@help_category.reload.navigation).to be_true
          end
        end

        context "trueの場合" do
          before do
            @help_category = create(:help_category, navigation: true)
          end

          it "falseにすること" do
            subject
            expect(@help_category.reload.navigation).to be_false
          end
        end
      end
    end
  end
end

