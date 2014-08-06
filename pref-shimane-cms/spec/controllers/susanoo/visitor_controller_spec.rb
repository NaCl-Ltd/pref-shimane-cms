require 'spec_helper'

describe Susanoo::VisitorsController do
  describe "フィルタ" do
    describe "#set_mobile" do
      controller do
        def view
          render text: 'ok'
        end
      end

      before do
        @routes.draw do
          resources :anonymous, only: :none do
            collection do
              get :view
            end
          end
        end
      end

      context "モバイル用のURLでアクセスした場合" do
        before do
          request.path = '/genre11/test.html.i'
          get :view
        end

        it "@mobileにtrueが設定されること" do
          expect(assigns[:mobile]).to be_true
        end
      end
    end
  end

  describe "アクション" do
    describe "GET view" do
      describe "正常系" do
        let(:view_name) { 'susanoo/visitors/normal/show' }

        before do
          allow_any_instance_of(Susanoo::PageView).to receive(:rendering_view_name).and_return(view_name)
          request.path = '/genre11/test.html'
          get :view
        end

        it "PageViewから返される名前のviewをrenderしていること" do
          expect(response).to render_template(view_name)
        end

        context "TOPページではない場合" do
          before do
            get :view
          end

          it "PageViewインスタンスを作成していること" do
            expect(assigns[:page_view]).to be_a(Susanoo::PageView)
          end
        end

        context "TOPページの場合" do
          before do
            Susanoo::PageView.any_instance.stub(:top?).and_return(true)
            request.path = '/'
          end

          it "広告をセットするメソッドを呼び出していること" do
            controller.should_receive(:set_advertisement)
            get :view
          end
        end
      end
    end

    describe "#preview" do
      describe "正常系" do
        let(:page_content) { create(:page_content) }
        let(:view_name) { 'susanoo/visitors/normal/show' }

        before do
          allow_any_instance_of(Susanoo::PageView).to receive(:rendering_view_name).and_return(view_name)
          get :preview, id: page_content.id
        end

        it "PageViewインスタンスを作成していること" do
          expect(assigns[:page_view]).to be_a(Susanoo::PageView)
        end

        it "@previewにtrueを設定していること" do
          expect(assigns[:preview]).to be_true
        end

        it "PageViewから取得したViewの名前をrenderしていること" do
          expect(response).to render_template(view_name)
        end
      end
    end
  end
end

