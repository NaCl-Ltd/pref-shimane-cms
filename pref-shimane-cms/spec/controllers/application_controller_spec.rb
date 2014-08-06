require 'spec_helper'

describe ApplicationController do
  describe "プライベート" do
    describe "#feature_check" do
      let(:user) { create(:user) }

      context "ログイン中の場合" do
        before do
          controller.stub(:current_user).and_return(user)
        end

        context "visitors以外へのアクセスの場合" do
          context "所属の仕様機能がclassicの場合" do
            before do
              request.path = '/susanoo/index.hyml'
              user.stub_chain(:section, :susanoo?).and_return(false)
            end

            it "403エラーを返すこと" do
              controller.should_receive(:render).with(text: '403 Forbidden', status: 403)
              expect(controller.send(:feature_check)).to eq(nil)
            end
          end
        end

        context "visitorsへのアクセスの場合" do
          before do
            controller.params[:controller] = 'susanoo/visitors'
          end

          it "nilを返すこと" do
            expect(controller.send(:feature_check)).to be_nil
          end
        end
      end
    end
  end
end
