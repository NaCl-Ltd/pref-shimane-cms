require 'spec_helper'

describe LostLinkCheck::Susanoo::LostLinksController do
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
          expect(response.body).to eq("ok")
        end
      end

      controller do
        %w(index destroy).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        @routes.draw do
          resources :anonymous, only: [:index, :destroy]
        end
        @lost_link = create(:lost_link)
      end

      context "未ログイン状態" do
        it_behaves_like("未ログイン時のアクセス制限", :get, :index) {before{get :index, use_route: :lost_link_check}}
        it_behaves_like("未ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy, id: @lost_link.id, use_route: :lost_link_check}}
      end

      context "ログイン状態" do
        it_behaves_like("ログイン時のアクセス制限", :get, :index) {before{get :index, use_route: :classic}}
        it_behaves_like("ログイン時のアクセス制限", :delete, :destroy) {before{delete :destroy, id: @lost_link.id, use_route: :classic}}
      end
    end

    describe "set_lost_link" do
      controller do
        %w(destroy).each do |act|
          define_method(act) do
            render text: "ok"
          end
        end
      end

      before do
        # 他のフィルタを停止
        controller.stub(:login_required).and_return(true)
        @routes.draw do
          resources :anonymous, only: [:index, :destroy]
        end
        create(:lost_link)
      end

      let(:lost_link){LostLink.first}

      shared_examples_for "インスタンス変数@lost_linkが正しく設定されているかの検証" do
        it "インスタンス変数@lost_linkがLostLinkクラスのインスタンスであること" do
          assigns[:lost_link].should be_kind_of(LostLink)
        end

        it "インスタンス変数@lost_linkのidがパラメータ:idで送った値と等しいこと" do
          (assigns[:lost_link].id == lost_link.id).should be_true
        end
      end

      context "DELETE destroyにアクセスしたとき" do
        before do
          delete :destroy, id: lost_link.id, use_route: :classic
        end
        it_behaves_like "インスタンス変数@lost_linkが正しく設定されているかの検証"
      end
    end
  end

  describe "アクション" do
    # NOTE: redirect先が Engine でなくなるため
    routes { LostLinkCheck::Engine.routes }

    before do
      @user = login(create(:user))
    end

    describe "GET index" do
      describe "正常系" do
        before do
          2.times do
            create(:lost_link, side_type: LostLink::INSIDE_TYPE, section_id: @user.section_id)
            create(:lost_link, side_type: LostLink::OUTSIDE_TYPE, section_id: @user.section_id)
            create(:lost_link, side_type: LostLink::INSIDE_TYPE, section_id: 2)
            create(:lost_link, side_type: LostLink::OUTSIDE_TYPE, section_id: 2)
          end
        end
        subject{get :index}

        it "200が返ること" do
          expect(subject).to be_success
        end

        it "indexがrenderされること" do
          expect(subject).to render_template(:index)
        end

        context "@insidesの検証" do
          before do
            subject
          end

          it "side_type=INSIDE_TYPEであること" do
            assigns[:insides].each do |ll|
              expect(ll.side_type).to eq(LostLink::INSIDE_TYPE)
            end
          end

          it "section_idがcurrent_userのsection_idと等しいこと" do
            assigns[:insides].each do |ll|
              expect(ll.section_id).to eq(@user.section_id)
            end
          end

          it "idの降順で取得されていること" do
            expect(assigns[:insides]).to eq(assigns[:insides].sort_by{|a|-a.id})
          end
        end

        context "@outsidesの検証" do
          before do
            subject
          end

          it "side_type=OUTSIDE_TYPEであること" do
            assigns[:outsides].each do |ll|
              expect(ll.side_type).to eq(LostLink::OUTSIDE_TYPE)
            end
          end

          it "section_idがcurrent_userのsection_idと等しいこと" do
            assigns[:outsides].each do |ll|
              expect(ll.section_id).to eq(@user.section_id)
            end
          end

          it "idの降順で取得されていること" do
            expect(assigns[:outsides]).to eq(assigns[:outsides].sort_by{|a|-a.id})
          end
        end
      end
    end

    describe "DELETE destroy" do
      before do
        create(:lost_link)
      end
      let(:lost_link){LostLink.first}

      subject{delete :destroy, id: lost_link.id}

      describe "正常系" do
        it "indexへリダイレクトすること" do
          expect(subject).to redirect_to(susanoo_lost_links_path)
        end

        it "destroyメソッドが呼ばれること" do
          LostLink.any_instance.should_receive(:destroy)
          subject
        end

        it "選択したレコードが削除されていること" do
          expect{subject}.to change(LostLink, :count).by(-1)
        end
      end
    end
  end
end
