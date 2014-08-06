require 'spec_helper'

describe Susanoo::Admin::InfosController do
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
      [:index, :show, :new, :create, :edit, :update, :destroy].each do |method|
        define_method(method) do
          render text: :OK
        end
      end
    end

    describe "admin_required" do
      context "未ログイン状態の場合" do
        it_should_behave_like("未ログイン時のアクセス制限", :index) { before {get :index } }
        it_should_behave_like("未ログイン時のアクセス制限", :show) { before {get :show, id: 1 } }
        it_should_behave_like("未ログイン時のアクセス制限", :new) { before {get :new } }
        it_should_behave_like("未ログイン時のアクセス制限", :create) { before {post :create } }
        it_should_behave_like("未ログイン時のアクセス制限", :edit) { before {get :edit, id: 1 } }
        it_should_behave_like("未ログイン時のアクセス制限", :update) { before {patch :update, id: 1 } }
        it_should_behave_like("未ログイン時のアクセス制限", :destory) { before {delete :destroy, id: 1 } }
      end

      context "ログイン状態の場合" do
        context "情報提供責任者の場合" do
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :index) { before {get :index } }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :show) { before {get :show, id: 1 } }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :new) { before {get :new } }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :create) { before {post :create } }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :edit) { before {get :edit, id: 1 } }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :update) { before {patch :update, id: 1 } }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :destory) { before {delete :destroy, id: 1 } }
        end

        context "一般ユーザの場合" do
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :index) { before {get :index } }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :show) { before {get :show, id: 1 } }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :new) { before {get :new } }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :create) { before {post :create } }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :edit) { before {get :edit, id: 1 } }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :update) { before {patch :update, id: 1 } }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :destory) { before {delete :destroy, id: 1 } }
        end
      end
    end
  end

  describe "アクション" do
    before do
      login(create(:user))
    end

    describe "GET index" do
      describe "正常系" do
        let(:infos)    { Info.all.page(nil) }

        it "お知らせを全件取得していること" do
          get :index
          expect(assigns(:infos).to_a).to eq(infos.to_a)
        end
      end
    end

    describe "GET new" do
      describe "正常系" do
        before do
          get :new
        end

        it "新しいUserインスタンスを作成していること" do
          expect(assigns(:info).new_record?).to be_true
        end
      end
    end


    describe "POST create" do
      let(:user) { {name: 'test'} }

      subject { post :create, {info: {title: 'test', tes: :teset}} }

      describe "正常系" do
        context "バリデーションに成功した場合" do
          before :each do
            Info.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "一覧画面へリダイレクトすること" do
              Info.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(susanoo_admin_infos_path)
            end
          end

          context "保存に失敗した場合" do
            it "作成画面を再描画していること" do
              Info.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template(:new)
            end
          end
        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before :each do
            Info.any_instance.stub(:save).and_return(false)
          end

          it "作成画面を再描画していること" do
            expect(subject).to render_template(:new)
          end
        end
      end
    end

    describe "GET edit" do
      subject { get :edit, id: @info.id }

      describe "正常系" do
        it '編集画面をrenderしていること' do
          @info = create(:info)
          expect(subject).to render_template(:edit)
        end
      end
    end

    describe "GET show" do
      subject { get :show, id: @info.id }

      describe "正常系" do
        it '編集画面をrenderしていること' do
          @info = create(:info)
          expect(subject).to render_template(:show)
        end
      end
    end

    describe "PATCH update" do
      let(:user) { {name: ''} }

      before do
        @info  = create(:info)
      end

      subject { patch :update, {id: @info.id, info: @info.attributes} }

      describe "正常系" do
        context "バリデーションに成功した場合" do
          before do
            Info.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "一覧画面へリダイレクトすること" do
              Info.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(susanoo_admin_infos_path)
            end
          end

          context "保存に失敗した場合" do
            it "作成画面を再描画していること" do
              Info.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template(:edit)
            end
          end

        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before do
            Info.any_instance.stub(:save).and_return(false)
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
          @info = create(:info)
        end

        subject { delete :destroy, id: @info.id }

        it "Infoの数が減っていること" do
          old_count = Info.count
          expect{subject}.to change {Info.count}.from(old_count).to(old_count - 1)
        end

        it "一覧画面へリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_admin_infos_path)
        end
      end
    end
  end
end
