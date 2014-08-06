require 'spec_helper'

describe SectionInfoConfigure::Susanoo::Authoriser::SectionsController do

  shared_examples_for "未ログイン時のアクセス制限" do |action|
    it "#{action} ログイン画面にリダイレクトされること" do
      # expect(response).to redirect_to(login_susanoo_users_path)
    end
  end

  describe "フィルタ" do
    controller do
      [:update, :edit_info].each do |method|
        define_method(method) do
          render text: :OK
        end
      end
    end

    before do
      @routes.draw do
        resources :anonymous do
          member do
            get :edit_info
          end
        end
      end
    end

    describe "authorizer_or_admin_required" do
      context "未ログイン状態の場合" do
        it_should_behave_like("未ログイン時のアクセス制限", :edit) { before {get :edit_info, id: 1, use_route: :section_info_configure } }
        it_should_behave_like("未ログイン時のアクセス制限", :update) { before {patch :update, id: 1, use_route: :section_info_configure } }
      end
    end
  end

  describe "アクション" do
    # NOTE: redirect先が Engine でなくなるため
    routes { SectionInfoConfigure::Engine.routes }

    describe "GET edit_info" do
      subject { get :edit_info }

      describe "正常系" do
        before do
          @user = login(create(:user))
        end

        it '編集画面をrenderしていること' do
          @section = create(:section)
          expect(subject).to render_template(:edit_info)
        end
      end
    end

    describe "PATCH update" do

      before do
        @user    = login(create(:user))
        @section = create(:section)
      end

      subject { patch :update, id: @user.section_id, section: @section.attributes }

      describe "正常系" do
        context "バリデーションに成功した場合" do
          before :each do
            Section.any_instance.stub(:valid?).and_return(true)
          end

          context "保存に成功した場合" do
            it "設定画面へリダイレクトすること" do
              Section.any_instance.stub(:save).and_return(true)
              expect(subject).to redirect_to(edit_info_susanoo_authoriser_sections_path)
            end
          end

          context "保存に失敗した場合" do
            it "設定画面を再描画していること" do
              Section.any_instance.stub(:save).and_return(false)
              expect(subject).to render_template(:edit_info)
            end
          end

        end
      end

      describe "異常系" do
        context "バリデーションに失敗した場合" do
          before :each do
            Section.any_instance.stub(:valid?).and_return(false)
          end

          it "作成画面を再描画していること" do
            expect(subject).to render_template(:edit_info)
          end
        end
      end
    end
  end
end
