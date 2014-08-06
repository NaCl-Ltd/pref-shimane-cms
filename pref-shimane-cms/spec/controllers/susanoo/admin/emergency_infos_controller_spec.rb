require 'spec_helper'

describe Susanoo::Admin::EmergencyInfosController do
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

  shared_examples_for "EmergencyInfoインスタンスの取得" do |action|
    before do
      login(create(:user))
      create(:emergency_info)
    end
    it "#{action} 保存済みのレコードを取得していること" do
      expect(assigns[:emergency_info].persisted?).to be_true
    end
  end


  shared_examples_for "EmergencyInfoインスタンスの作成" do |action|
    before{ login(create(:user)) }
    it '新規レコードを作成していること' do
      expect(assigns[:emergency_info].new_record?).to be_true
    end
  end

  describe "フィルタ" do
    controller do
      [:edit, :update, :stop_public].each do |method|
        define_method(method) do
          render text: :OK
        end
      end
    end

    before do
      @routes.draw do
        resources :anonymous do
          collection do
            get :edit
            patch :update
            patch :stop_public
          end
        end
      end
    end

    describe "admin_required" do
      context "未ログイン状態の場合" do
        it_should_behave_like("未ログイン時のアクセス制限", :edit) { before {get :edit } }
        it_should_behave_like("未ログイン時のアクセス制限", :update) { before {patch :update} }
        it_should_behave_like("未ログイン時のアクセス制限", :stop_public) { before {patch :stop_public} }
      end

      context "ログイン状態の場合" do
        context "情報提供責任者の場合" do
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :edit) { before {get :edit} }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :update) { before {patch :update} }
          it_should_behave_like("情報提供責任者ログイン時のアクセス制限", :stop_public) { before {patch :stop_public} }
        end

        context"一般ユーザの場合" do
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :edit) { before {get :edit} }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :update) { before {patch :update} }
          it_should_behave_like("一般ユーザログイン時のアクセス制限", :stop_public) { before {patch :stop_public} }
        end
      end
    end

    describe 'set_emergency_info' do
      context "緊急お知らせ情報が存在する場合" do
        examaple_name = "EmergencyInfoインスタンスの取得"
        it_should_behave_like(examaple_name, :edit) { before {get :edit} }
        it_should_behave_like(examaple_name, :update) { before {patch :update} }
      end

      context "緊急お知らせ情報が存在しない場合" do
        examaple_name = "EmergencyInfoインスタンスの作成"
        it_should_behave_like(examaple_name, :edit) { before {get :edit} }
        it_should_behave_like(examaple_name, :update) { before {patch :update} }
      end
    end
  end

  describe "アクション" do
    before do
      login(create(:user))
    end

    describe "GET edit" do
      describe "正常系" do
        subject { get :edit }


        it 'editをrenderしていること' do
          expect(subject).to render_template(:edit)
        end
      end
    end

    describe "PATCH update" do
      describe "正常系" do
        let(:user) { {name: ''} }

        before do
          @emergency_info = create(:emergency_info)
        end

        subject { patch :update, {id: @emergency_info.id, emergency_info: @emergency_info.attributes} }

        context "バリデーションに成功した場合" do
          before :each do
            EmergencyInfo.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "一覧画面へリダイレクトすること" do
              EmergencyInfo.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(susanoo_dashboards_path)
            end
          end

          context "保存に失敗した場合" do
            it "作成画面を再描画していること" do
              EmergencyInfo.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template(:edit)
            end
          end

        end

        describe "異常系" do
          context "バリデーションに失敗した場合" do
            before :each do
              EmergencyInfo.any_instance.stub(:valid?).and_return(false)
            end

            it "作成画面を再描画していること" do
              expect(subject).to render_template(:edit)
            end
          end
        end
      end
    end

    describe "PATCH stop_public" do
      describe "正常系" do
        let(:user) { {name: ''} }

        subject{ patch :stop_public }

        it "EmgergencyInfoへstop_publicを呼び出していること" do
          EmergencyInfo.should_receive(:stop_public)
          subject
        end

        it "トップページへリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_dashboards_path)
        end
      end
    end
  end

end
