require 'spec_helper'

describe ConsultManagement::Susanoo::Admin::ConsultsController do
  describe "フィルタ" do
    describe "set_consult" do
      controller do
        %w(edit update destroy).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      shared_examples_for "Consultインスタンスの設定"  do |met, act|
        it "#{met.upcase} #{act}にアクセスしたとき、Consultのインスタンスが設定されていること" do
          expect(assigns[:consult]).to eq(@consult)
        end
      end

      before do
        login(create(:user))
        @consult = create(:consult)
      end

      it_behaves_like("Consultインスタンスの設定", :get, :edit) {before{get :edit, id: @consult.id}}
      it_behaves_like("Consultインスタンスの設定", :patch, :update) {before{patch :update, id: @consult.id}}
      it_behaves_like("Consultインスタンスの設定", :delete, :destroy){before{delete :destroy, id: @consult.id}}
    end
  end

  describe "アクション" do
    # NOTE: redirect先が Engine でなくなるため
    routes { ConsultManagement::Engine.routes }

    before do
      login(create(:user))
    end

    describe "GET index" do
      let(:consults) { [create(:consult)] }

      before do
        get :index
      end

      it "@consultsに全件設定していること" do
        expect(assigns[:consults]).to eq(consults)
      end
    end

    describe "GET edit" do
      let(:consult) { create(:consult) }

      before do
        xhr :get, :edit, id: consult.id
      end

      it "ConsultCategoryをして@c_caに設定していること" do
        expect(assigns[:c_ca]).to eq(ConsultManagement::ConsultCategory.all)
      end

      it "editをrenderしていること" do
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      let(:consult_params) { build(:consult).attributes }

      describe "正常系" do
        before do
          xhr :post, :create, consult: consult_params
          @json = JSON.parse(response.body)
        end

        it "@consultが保存されていること" do
          expect(assigns[:consult]).to be_persisted
        end

        it "statusにtrueが入っていること" do
          expect(@json['status']).to be_true
        end

        it "flash[:notice]が正しくセットされていること" do
          expect(flash[:notice]).to eq(I18n.t('consult_management.susanoo.admin.consults.create.success'))
        end
      end

      describe "異常系" do
        context "saveに失敗した場合" do
          before do
            ConsultManagement::Consult.any_instance.stub(:save).and_return(false)
            xhr :post, :create, consult: consult_params
            @json = JSON.parse(response.body)
          end

          it "保存されていないこと" do
            expect(assigns[:consult]).to be_a_new(ConsultManagement::Consult)
          end

          it "statusにfalseが入っていること" do
            expect(@json['status']).to be_false
          end
        end
      end
    end


    describe "PUT update" do
      let(:consult) { create(:consult) }
      let(:consult_params) { consult.attributes.merge(name: 'new-name') }

      describe "正常系" do
        before do
          xhr :patch, :update, id: consult.id, consult: consult_params
          @json = JSON.parse(response.body)
        end

        it "@consultが更新されていること" do
          expect(assigns[:consult]).to eq(ConsultManagement::Consult.new(consult_params))
        end

        it "trueが入っていること" do
          expect(@json['status']).to be_true
        end

        it "flash[:notice]が正しくセットされていること" do
          expect(flash[:notice]).to eq(I18n.t('consult_management.susanoo.admin.consults.update.success'))
        end
      end

      describe "異常系" do
        context "saveに失敗した場合" do
          before do
            ConsultManagement::Consult.any_instance.stub(:update).and_return(false)
            patch :update, id: consult.id, consult: consult_params
            @json = JSON.parse(response.body)
          end

          it "falseが設定されていること" do
            expect(@json['status']).to be_false
          end
        end
      end
    end

    describe "DELETE destroy" do
      let!(:consult) { create(:consult) }

      subject{ delete :destroy, id: consult.id }

      it "Consultの数が減っていること" do
        expect{subject}.to change(ConsultManagement::Consult, :count).by(-1)
      end

      it "正しくリダイレクトすること" do
        expect(subject).to redirect_to(susanoo_admin_consults_path)
      end
    end

    describe "POST search" do
      context "params[:consult_category_id]が含まれていない場合" do
        let(:consults) { [create(:consult)] }

        before do
          post :search
        end

        it "@consultsに全件設定していること" do
          expect(assigns[:consults]).to eq(consults)
        end
      end

      context "params[:consult_category_id]が含まれている場合" do
        let(:consult_category) { create(:consult_category) }
        let(:consults) { [create(:consult, consult_categories: [consult_category])] }

        before do
          2.times{ create(:consult) }
          post :search, consult_category_id: consult_category.id
        end

        it "@consultsに全件設定していること" do
          expect(assigns[:consults]).to eq(consults)
        end
      end
    end
  end
end
