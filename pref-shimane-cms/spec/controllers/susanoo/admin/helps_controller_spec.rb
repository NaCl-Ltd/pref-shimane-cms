require 'spec_helper'

describe Susanoo::Admin::HelpsController do
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
      %w(index, new, create, edit, update, destroy, update_sort, configure, edit_caption, save_caption, destroy_caption, caption_change_public, action_configure, edit_action, save_action, destroy_action).each do |method|
        define_method(method) do
          render text: :OK
        end
      end
    end

    before do
      @routes.draw do
        resources :anonymous, except: [:destory] do
          collection do
            post :update_sort
            post :save_caption
            get :configure
            get :edit_caption
            get :action_configure
            get :edit_action
            post :save_action
          end

          member do
            get :caption_change_public
            delete :destroy_caption
            delete :destroy_action
          end
        end
      end
    end

    describe "admin_required" do
      context "未ログイン状態の場合" do
        shared_example_name = "未ログイン時のアクセス制限"

        it_should_behave_like(shared_example_name, :index) { before {get :index } }
        it_should_behave_like(shared_example_name, :new) { before {get :new } }
        it_should_behave_like(shared_example_name, :create) { before {post :create } }
        it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
        it_should_behave_like(shared_example_name, :update) { before {patch :update, id: 1 } }
        it_should_behave_like(shared_example_name, :update_sort) { before {post :update_sort } }
        it_should_behave_like(shared_example_name, :save_caption) { before {post :save_caption } }
        it_should_behave_like(shared_example_name, :configure) { before {get :configure } }
        it_should_behave_like(shared_example_name, :edit_caption) { before {get :edit_caption } }
        it_should_behave_like(shared_example_name, :action_configure) { before {get :action_configure } }
        it_should_behave_like(shared_example_name, :edit_action) { before {get :edit_action } }
        it_should_behave_like(shared_example_name, :save_action) { before {post :save_action } }
        it_should_behave_like(shared_example_name, :caption_change_public) { before {get :caption_change_public, id: 1 } }
        it_should_behave_like(shared_example_name, :destroy_caption) { before {delete :destroy_caption, id: 1 } }
        it_should_behave_like(shared_example_name, :destroy_action) { before {delete :destroy_action, id: 1 } }
      end

      context "ログイン状態の場合" do
        context "情報提供責任者の場合" do
          shared_example_name = "情報提供責任者ログイン時のアクセス制限"

          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :new) { before {get :new } }
          it_should_behave_like(shared_example_name, :create) { before {post :create } }
          it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
          it_should_behave_like(shared_example_name, :update) { before {patch :update, id: 1 } }
          it_should_behave_like(shared_example_name, :update_sort) { before {post :update_sort } }
          it_should_behave_like(shared_example_name, :save_caption) { before {post :save_caption } }
          it_should_behave_like(shared_example_name, :configure) { before {get :configure } }
          it_should_behave_like(shared_example_name, :edit_caption) { before {get :edit_caption } }
          it_should_behave_like(shared_example_name, :action_configure) { before {get :action_configure } }
          it_should_behave_like(shared_example_name, :edit_action) { before {get :edit_action } }
          it_should_behave_like(shared_example_name, :save_action) { before {post :save_action } }
          it_should_behave_like(shared_example_name, :caption_change_public) { before {get :caption_change_public, id: 1 } }
          it_should_behave_like(shared_example_name, :destroy_caption) { before {delete :destroy_caption, id: 1 } }
          it_should_behave_like(shared_example_name, :destroy_action) { before {delete :destroy_action, id: 1 } }

        end

        context "一般ユーザの場合" do
          shared_example_name = "一般ユーザログイン時のアクセス制限"

          it_should_behave_like(shared_example_name, :index) { before {get :index } }
          it_should_behave_like(shared_example_name, :new) { before {get :new } }
          it_should_behave_like(shared_example_name, :create) { before {post :create } }
          it_should_behave_like(shared_example_name, :edit) { before {get :edit, id: 1 } }
          it_should_behave_like(shared_example_name, :update) { before {patch :update, id: 1 } }
          it_should_behave_like(shared_example_name, :update_sort) { before {post :update_sort } }
          it_should_behave_like(shared_example_name, :save_caption) { before {post :save_caption } }
          it_should_behave_like(shared_example_name, :configure) { before {get :configure } }
          it_should_behave_like(shared_example_name, :edit_caption) { before {get :edit_caption } }
          it_should_behave_like(shared_example_name, :action_configure) { before {get :action_configure } }
          it_should_behave_like(shared_example_name, :edit_action) { before {get :edit_action } }
          it_should_behave_like(shared_example_name, :save_action) { before {post :save_action } }
          it_should_behave_like(shared_example_name, :caption_change_public) { before {get :caption_change_public, id: 1 } }
          it_should_behave_like(shared_example_name, :destroy_caption) { before {delete :destroy_caption, id: 1 } }
          it_should_behave_like(shared_example_name, :destroy_action) { before {delete :destroy_action, id: 1 } }

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
        context "help_category_idが存在しない場合" do
          before do
            @help_contents = []
            10.times { @help_contents << create(:help_content) }
          end

          it "HelpContentから全件取得していること" do
            subject
            expect(assigns[:help_contents]).to eq(@help_contents)
          end

          it "indexをrenderしていること" do
            expect(subject).to render_template(:index)
          end
        end

        context "help_category_idが存在する場合" do
          before do
            @big_category = create(:help_category)
            @middle_category = create(:help_category, parent_id: @big_category.id)
            @small_category = create(:help_category, parent_id: @middle_category.id)

            @help_content = create(:help_content)
          end

          subject{ get :index, help_category_id: @big_category.id }

          context "ヘルプのカテゴリのパラメータのカテゴリの子カテゴリの場合" do
            before do
              @help = create(:help, help_category_id: @small_category.id, help_content_id: @help_content.id)
            end

            it "Helpからhelp_category_idが一致するレコードを全件取得していること" do
              subject
              expect(assigns[:help_contents]).to eq([@help_content])
            end
          end

          context "ヘルプのカテゴリのパラメータのカテゴリの中カテゴリの場合" do
            before do
              @help = create(:help, help_category_id: @middle_category.id, help_content_id: @help_content.id)
            end

            it "Helpからhelp_category_idが一致するレコードを全件取得していること" do
              subject
              expect(assigns[:help_contents]).to eq([@help_content])
            end
          end

          context "ヘルプのカテゴリのパラメータのカテゴリの大カテゴリの場合" do
            before do
              @help = create(:help, help_category_id: @big_category.id, help_content_id: @help_content.id)
            end

            it "Helpからhelp_category_idが一致するレコードを全件取得していること" do
              subject
              expect(assigns[:help_contents]).to eq([@help_content])
            end
          end
        end

        context "アクセスがajaxの場合" do
          subject{ xhr :get, :index}

          it "テンプレートをrenderしていること" do
            expect(subject).to render_template("_index_row")
          end
        end

        it "HelpCategoryから大カテゴリを取得していること" do
          HelpCategory.should_receive(:big_categories)
          subject
        end
      end
    end

    describe "GET new" do
      subject{ get :new }

      describe "正常系" do
        it "新しいHelpレコードを作成していること" do
          subject
          expect(assigns[:help].new_record?).to be_true
        end

        it "newをrenderしていること" do
          expect(subject).to render_template(:new)
        end
      end
    end

    describe "POST create" do
      subject { post :create, {help: {name: 'name'}} }

      describe "正常系" do
        context "バリデーションに成功した場合" do
          before :each do
            Help.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "一覧画面へリダイレクトすること" do
              Help.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(susanoo_admin_helps_path)
            end
          end

          context "保存に失敗した場合" do
            it "作成画面を再描画していること" do
              Help.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template(:new)
            end
          end
        end
      end

      describe "異常系" do
        context "更新できないカラムのパラメータが含まれていた場合" do
          let(:number) { 100 }
          let(:help_params) { build(:help).attributes.merge(number: number) }

          before do
            post :create, help: help_params
          end

          it "更新されていないこと" do
            expect(assigns(:help).number).to be_nil
          end
        end

        context "バリデーションに失敗した場合" do
          before :each do
            Help.any_instance.stub(:save).and_return(false)
          end

          it "作成画面を再描画していること" do
            expect(subject).to render_template(:new)
          end
        end
      end
    end

    describe "GET edit" do
      before do
        @help_content = create(:help_content)
      end

      subject { get :edit, id: @help_content.id }

      describe "正常系" do
        it '編集画面をrenderしていること' do
          expect(subject).to render_template(:edit)
        end
      end
    end

    describe "PATCH update" do
      subject { patch :update, {id: @help_content.id, help_content: @help_content.attributes} }

      describe "正常系" do
        before do
          @help_content = create(:help_content)
        end

        context "保存に成功した場合" do
          it "一覧画面へリダイレクトすること" do
            HelpContent.any_instance.stub(:save).and_return(true)
            expect(subject).to redirect_to(susanoo_admin_helps_path)
          end
        end

        context "保存に失敗した場合" do
          it "作成画面を再描画していること" do
            HelpContent.any_instance.stub(:save).and_return(false)
            expect(subject).to render_template(:edit)
          end
        end
      end

      describe "異常系" do
        let(:number) { 1 }

        before do
          @help_content = create(:help_content)
        end

        subject { patch :update, {id: @help_content.id, help_content: @help_content.attributes} }

        context "バリデーションに失敗した場合" do
          before :each do
            HelpContent.any_instance.stub(:save).and_return(false)
          end

          it "作成画面を再描画していること" do
            expect(subject).to render_template(:edit)
          end
        end
      end
    end

    describe "DELETE destroy" do
      describe "正常系" do
        before do
          @help_content = create(:help_content)
        end

        subject { delete :destroy, id: @help_content.id }

        it "Infoの数が減っていること" do
          old_count = HelpContent.count
          expect{subject}.to change {HelpContent.count}.from(old_count).to(old_count - 1)
        end

        it "一覧画面へリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_admin_helps_path)
        end
      end
    end

    describe "POST update_sort" do
      describe "正常系" do
        before do
          @helps = []
          3.times{|i| @helps << create(:help, name: "name")}
        end

        subject{ post :update_sort, helps: @helps.map(&:id) }

        it "Helpを正しい引数でupdateしていること" do
          @helps.each_with_index do |h, index|
            Help.should_receive(:update).with(h.id.to_s, number: index)
          end
          subject
        end
      end
    end

    describe "GET configure" do
      describe "正常系" do
        before do
          @help_content = create(:help_content, content: 'content')
          @help = create(:help, name: 'name', help_content_id: @help_content.id)

          @help_categories = []
          3.times{|i| @help_categories << create(:help_category, name: 'name', parent_id: i)}
        end

        subject { get :configure, help_content_id: @help_content.id }

        it "HelpContentを取得していること" do
          subject
          expect(assigns[:help_content]).to eq(@help_content)
        end

        it "configureをrenderしていること" do
          expect(subject).to render_template(:configure)
        end
      end
    end

    describe "GET edit_caption" do
      describe "正常系" do
        before do
          @help_content = create(:help_content, content: 'content')
          @help = create(:help, name: 'name', help_content_id: @help_content.id)

          @big_category = create(:help_category, name: 'name')
          @middle_category = create(:help_category, name: 'name', parent_id: @big_category.id)
          @small_category = create(:help_category, name: 'name', parent_id: @middle_category.id)
        end

        subject { get :edit_caption, id: @help.id }

        context "idが存在する場合" do
          it "Helpを取得していること" do
            subject
            expect(assigns[:help]).to eq(@help)
          end

          context "Helpのもつカテゴリが中カテゴリの場合" do
            before do
              @help.update(help_category_id: @big_category.id)
              subject
            end

            it "big_categoryに正しい値がセットされていること" do
              expect(assigns[:big_category]).to eq(@big_category)
            end

            it "small_categoriesに正しい値がセットされていること" do
              expect(assigns[:small_categories]).to eq([])
            end

            it "middle_categoriesに正しい値がセットされていること" do
              expect(assigns[:middle_categories]).to eq([@middle_category])
            end
          end

          context "Helpのもつカテゴリが中カテゴリの場合" do
            before do
              @help.update(help_category_id: @middle_category.id)
              subject
            end

            it "middle_categoryに正しい値がセットされていること" do
              expect(assigns[:middle_category]).to eq(@middle_category)
            end

            it "big_categoryに正しい値がセットされていること" do
              expect(assigns[:big_category]).to eq(@big_category)
            end

            it "small_categoriesに正しい値がセットされていること" do
              expect(assigns[:small_categories]).to eq([@small_category])
            end

            it "middle_categoriesに正しい値がセットされていること" do
              expect(assigns[:middle_categories]).to eq([@middle_category])
            end
          end

          context "Helpのもつカテゴリが小カテゴリの場合" do
            before do
              @help.update(help_category_id: @small_category.id)
              subject
            end

            it "small_categoryに正しい値がセットされていること" do
              expect(assigns[:small_category]).to eq(@small_category)
            end

            it "middle_categoryに正しい値がセットされていること" do
              expect(assigns[:middle_category]).to eq(@middle_category)
            end

            it "big_categoryに正しい値がセットされていること" do
              expect(assigns[:big_category]).to eq(@big_category)
            end

            it "small_categoriesに正しい値がセットされていること" do
              expect(assigns[:small_categories]).to eq([@small_category])
            end

            it "middle_categoriesに正しい値がセットされていること" do
              expect(assigns[:middle_categories]).to eq([@middle_category])
            end
          end
        end

        context "idが存在しない場合" do
          let(:help_content_id) { 1 }

          subject { get :edit_caption, help_content_id: help_content_id}

          it "Helpを作成していること" do
            subject
            expect(assigns[:help].new_record?).to be_true
          end

          it "help_content_idをセットしていること" do
            subject
            expect(assigns[:help].help_content_id).to eq(help_content_id)
          end

          it "big_categoryが存在しないこと" do
            subject
            expect(assigns[:big_category]).to eq(nil)
          end

          it "middle_categoriesに正しい値がセットされていること" do
            subject
            expect(assigns[:middle_categories]).to eq([])
          end

          it "small_categoriesに正しい値がセットされていること" do
            subject
            expect(assigns[:small_categories]).to eq([])
          end
        end

        it "大カテゴリを全件取得していること" do
          subject
          expect(assigns[:big_categories].to_a).to eq([@big_category])
        end

        it "edit_captionをrenderしていること" do
          expect(subject).to render_template("_edit_caption")
        end

      end
    end

    describe "POST save_caption" do
      subject { post :save_caption, {help: {name: 'name'}} }

      describe "正常系" do
        let(:help_content_id) { 1 }

        context "idが存在する場合" do
          before do
            @help = create(:help)
          end

          subject { post :save_caption, id: @help.id, help: {help_content_id: help_content_id} }

          it "レコードを取得していること" do
            subject
            expect(assigns[:help]).to eq(@help)
          end
        end

        context "idが存在しない場合" do
          subject { post :save_caption, help: {name: 'name', help_content_id: help_content_id} }

          it "新しいレコードを作成していること" do
            subject
            expect(assigns[:help].new_record?).to be_true
          end

          it "help_content_idをセットしていること" do
            subject
            expect(assigns[:help].help_content_id).to eq(help_content_id)
          end
        end

        context "params[:help_category_ids]が存在する場合" do
          let(:help_category_id) { 1 }

          subject { post :save_caption, help: {name: 'name', help_content_id: help_content_id, help_category_ids: [1, 2, help_content_id]} }

          it "最後に設定されているcategory_idを設定していること" do
            subject
            expect(assigns[:help].help_content_id).to eq(help_content_id)

          end
        end

        context "バリデーションに成功した場合" do
          before :each do
            Help.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "アラートをrenderすること" do
              Help.any_instance.stub(:save).and_return(true)
              expect(subject).to render_template("shared/helps/_alert")
            end
          end

          context "保存に失敗した場合" do
            it "アラートを再描画していること" do
              Help.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template("shared/helps/_alert")
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before :each do
            Help.any_instance.stub(:save).and_return(false)
          end

          it "アラートをrenderしていること" do
            expect(subject).to render_template("shared/helps/_alert")
          end
        end

        context "更新できないカラムのパラメータが含まれている場合" do
          let(:number) { 100 }
          subject { post :save_caption, {help: {name: 'name', number: number}} }

          it "更新されていないこと" do
            subject
            expect(assigns[:help].number).to_not eq(number)
          end
        end
      end
    end

    describe "DELETE destroy_caption" do
      describe "正常系" do
        before do
          help_content = create(:help_content)
          @help = create(:help, help_content_id: help_content.id)
          3.times { create(:help, help_content_id: help_content.id) }
        end

        subject { delete :destroy_caption, id: @help.id }

        it "Helpの数が減っていること" do
          old_count = Help.count
          expect{subject}.to change {Help.count}.from(old_count).to(old_count - 1)
        end

        it "見出し一覧画面へリダイレクトすること" do
          expect(subject).to redirect_to(configure_susanoo_admin_helps_path(help_content_id: @help.help_content_id))
        end

        context "HelpContentにひもづくHelpがなくなった場合" do
          before do
            help_content = create(:help_content)
            @help = create(:help, help_content_id: help_content.id)
          end

          it "HelpContentの数が減っていること" do
            old_count = HelpContent.count
            expect{subject}.to change {HelpContent.count}.from(old_count).to(old_count - 1)
          end

          it "ヘルプ一覧画面へリダイレクトすること" do
            expect(subject).to redirect_to(susanoo_admin_helps_path)
          end
        end
      end
    end

    describe "GET caption_change_public" do
      describe "正常系" do
        subject { get :caption_change_public, id: @help.id }

        it "設定一覧画面へリダイレクトすること" do
          @help = create(:help, public: 1)
          expect(subject).to redirect_to(configure_susanoo_admin_helps_path(help_content_id: @help.help_content_id))
        end

        context "非公開の場合" do
          before do
            @help = create(:help, public: 0)
          end

          subject { get :caption_change_public, id: @help.id }

          it "公開にすること" do
            subject
            expect(@help.reload.public).to eq(1)
          end
        end

        context "公開の場合" do
          before do
            @help = create(:help, public: 1)
          end

          subject { get :caption_change_public, id: @help.id }

          it "公開にすること" do
            subject
            expect(@help.reload.public).to eq(0)
          end
        end

      end
    end

    describe "GET action_configure" do
      describe "正常系" do
        before do
          help_category = create(:help_category)
          @help_actions = []
          3.times{|i| @help_actions << create(:help_action, help_category_id: help_category.id)}
        end

        subject { get :action_configure}

        it "HelpActionを取得していること" do
          subject
          expect(assigns[:help_actions]).to eq(@help_actions)
        end

        it "help_action_configureをrenderしていること" do
          expect(subject).to render_template(:action_configure)
        end
      end
    end

    describe "GET edit_action" do
      describe "正常系" do
        before do
          @help_action = create(:help_action)

          @big_category = create(:help_category, name: 'name')
          @middle_category = create(:help_category, name: 'name', parent_id: @big_category.id)
          @small_category = create(:help_category, name: 'name', parent_id: @middle_category.id)
        end

        subject { get :edit_action, id: @help_action.id }

        context "idが存在する場合" do
          it "HelpActionを取得していること" do
            subject
            expect(assigns[:help_action]).to eq(@help_action)
          end

          context "Helpのもつカテゴリが中カテゴリの場合" do
            before do
              @help_action.update(help_category_id: @big_category.id)
              subject
            end

            it "big_categoryに正しい値がセットされていること" do
              expect(assigns[:big_category]).to eq(@big_category)
            end

            it "small_categoriesに正しい値がセットされていること" do
              expect(assigns[:small_categories]).to eq([])
            end

            it "middle_categoriesに正しい値がセットされていること" do
              expect(assigns[:middle_categories]).to eq([@middle_category])
            end
          end

          context "Helpのもつカテゴリが中カテゴリの場合" do
            before do
              @help_action.update(help_category_id: @middle_category.id)
              subject
            end

            it "middle_categoryに正しい値がセットされていること" do
              expect(assigns[:middle_category]).to eq(@middle_category)
            end

            it "big_categoryに正しい値がセットされていること" do
              expect(assigns[:big_category]).to eq(@big_category)
            end

            it "small_categoriesに正しい値がセットされていること" do
              expect(assigns[:small_categories]).to eq([@small_category])
            end

            it "middle_categoriesに正しい値がセットされていること" do
              expect(assigns[:middle_categories]).to eq([@middle_category])
            end
          end

          context "Helpのもつカテゴリが小カテゴリの場合" do
            before do
              @help_action.update(help_category_id: @small_category.id)
              subject
            end

            it "small_categoryに正しい値がセットされていること" do
              expect(assigns[:small_category]).to eq(@small_category)
            end

            it "middle_categoryに正しい値がセットされていること" do
              expect(assigns[:middle_category]).to eq(@middle_category)
            end

            it "big_categoryに正しい値がセットされていること" do
              expect(assigns[:big_category]).to eq(@big_category)
            end

            it "small_categoriesに正しい値がセットされていること" do
              expect(assigns[:small_categories]).to eq([@small_category])
            end

            it "middle_categoriesに正しい値がセットされていること" do
              expect(assigns[:middle_categories]).to eq([@middle_category])
            end
          end
        end

        context "idが存在しない場合" do
          subject { get :edit_action}

          it "Helpを作成していること" do
            subject
            expect(assigns[:help_action].new_record?).to be_true
          end

          it "middle_categoriesに正しい値がセットされていること" do
            subject
            expect(assigns[:middle_categories]).to eq([])
          end

          it "small_categoriesに正しい値がセットされていること" do
            subject
            expect(assigns[:small_categories]).to eq([])
          end
        end

        it "大カテゴリを全件取得していること" do
          subject
          expect(assigns[:big_categories].to_a).to eq([@big_category])
        end

        it "edit_captionをrenderしていること" do
          expect(subject).to render_template("_edit_action")
        end

      end
    end

    describe "POST save_action" do
      subject { post :save_action, {help_action: {name: 'name'}} }

      describe "正常系" do
        context "idが存在する場合" do
          before do
            @help_action = create(:help_action)
          end

          subject { post :save_action, id: @help_action.id, help_action: {name: 'name'} }

          it "レコードを取得していること" do
            subject
            expect(assigns[:help_action]).to eq(@help_action)
          end
        end

        context "params[:help_category_ids]が存在する場合" do
          let(:help_category_id) { 3 }

          subject { post :save_action, help_action: {name: 'name'}, help_category_ids: [1, 2, help_category_id] }

          it "最後に設定されているcategory_idを設定していること" do
            subject
            expect(assigns[:help_action].help_category_id).to eq(help_category_id)
          end
        end

        context "バリデーションに成功した場合" do
          before :each do
            HelpAction.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "アラートをrenderすること" do
              HelpAction.any_instance.stub(:save).and_return(true)
              expect(subject).to render_template("shared/helps/_alert")
            end
          end

          context "保存に失敗した場合" do
            it "アラートを再描画していること" do
              HelpAction.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template("shared/helps/_alert")
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before :each do
            HelpAction.any_instance.stub(:save).and_return(false)
          end

          it "アラートをrenderしていること" do
            expect(subject).to render_template("shared/helps/_alert")
          end
        end
      end
    end

    describe "DELETE destroy_action" do
      describe "正常系" do
        before do
          @help_action = create(:help_action)
          3.times { create(:help_action) }
        end

        subject { delete :destroy_action, id: @help_action.id }

        it "HelpActionの数が減っていること" do
          old_count = HelpAction.count
          expect{subject}.to change {HelpAction.count}.from(old_count).to(old_count - 1)
        end

        it "見出し一覧画面へリダイレクトすること" do
          expect(subject).to redirect_to(action_configure_susanoo_admin_helps_path)
        end
      end
    end
  end
end

