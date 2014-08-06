require 'spec_helper'

describe ConsultManagement::Susanoo::Admin::ConsultCategoriesController do
  describe "フィルタ" do
    describe "set_consult_category" do
      controller do
        %w(edit update destroy).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      shared_examples_for "ConsultCategoryインスタンスの設定"  do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、ConsultCategoryのインスタンスが設定されていること" do
          expect(assigns[:consult_category]).to eq(@consult_category)
        end
      end

      before do
        login(create(:user))
        @consult_category = create(:consult_category)
      end

      it_behaves_like("ConsultCategoryインスタンスの設定", :get, :edit) {before{get :edit, id: @consult_category.id}}
      it_behaves_like("ConsultCategoryインスタンスの設定", :patch, :update) {before{patch :update, id: @consult_category.id}}
      it_behaves_like("ConsultCategoryインスタンスの設定", :delete, :destroy){before{delete :destroy, id: @consult_category.id}}
    end
  end

  describe "アクション" do
    # NOTE: redirect先が Engine でなくなるため
    routes { ConsultManagement::Engine.routes }

    before do
      login(create(:user))
    end

    describe "GET index" do
      before do
        get :index
      end

      it "indexをrenderしていること" do
        expect(response).to render_template(:index)
      end
    end

    describe "GET edit" do
      let(:consult_category) { create(:consult_category) }

      subject{ xhr :get, :edit, id: consult_category.id}

      it "editをrenderしていること" do
        expect(subject).to render_template(:edit)
      end
    end

    describe "POST create" do
      let(:consult_category_params) { build(:consult_category).attributes }

      describe "正常系" do
        before do
          xhr :post, :create, consult_category: consult_category_params
          @json = JSON.parse(response.body)
        end

        it "@consult_categoryが保存されていること" do
          expect(assigns[:consult_category]).to be_persisted
        end

        it "trueがセットされていること" do
          expect(@json['status']).to be_true
        end

        it "flash[:notice]が正しくセットされていること" do
          expect(flash[:notice]).to eq(I18n.t('consult_management.susanoo.admin.consult_categories.create.success'))
        end
      end

      describe "異常系" do
        context "saveに失敗した場合" do
          before do
            ConsultManagement::ConsultCategory.any_instance.stub(:save).and_return(false)
            post :create, consult_category: consult_category_params
            @json = JSON.parse(response.body)
          end

          it "保存されていないこと" do
            expect(assigns[:consult_category]).to be_a_new(ConsultManagement::ConsultCategory)
          end

          it "falseがセットされていること" do
            expect(@json['status']).to be_false
          end
        end
      end
    end

    describe "PUT update" do
      let(:consult_category) { create(:consult_category) }
      let(:consult_category_params) { consult_category.attributes.merge(name: 'new-name') }

      describe "正常系" do
        before do
          xhr :patch, :update, id: consult_category.id, consult_category: consult_category_params
          @json = JSON.parse(response.body)
        end

        it "@consult_categoryが更新されていること" do
          expect(assigns[:consult_category]).to eq(ConsultManagement::ConsultCategory.new(consult_category_params))
        end

        it "trueがセットされていること" do
          expect(@json['status']).to be_true
        end

        it "flash[:notice]が正しくセットされていること" do
          expect(flash[:notice]).to eq(I18n.t('consult_management.susanoo.admin.consult_categories.update.success'))
        end
      end

      describe "異常系" do
        context "saveに失敗した場合" do
          before do
            ConsultManagement::ConsultCategory.any_instance.stub(:update).and_return(false)
            xhr :patch, :update, id: consult_category.id, consult_category: consult_category_params
            @json = JSON.parse(response.body)
          end

          it "falseがセットされていること" do
            expect(@json['status']).to be_false
          end
        end
      end
    end

    describe "DELETE destroy" do
      let!(:consult_category) { create(:consult_category) }

      subject{ delete :destroy, id: consult_category.id }

      it "ConsultCategoryの数が減っていること" do
        expect{subject}.to change(ConsultManagement::ConsultCategory, :count).by(-1)
      end

      it "正しくリダイレクトすること" do
        expect(subject).to redirect_to(susanoo_admin_consult_categories_path)
      end
    end
  end
end
