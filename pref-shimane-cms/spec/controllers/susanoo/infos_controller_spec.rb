require 'spec_helper'

describe Susanoo::InfosController do
  describe "アクション" do
    describe "GET show" do
      let(:info) { create(:info) }

      subject { get :show, id: info.id }

      describe "正常系" do
        it "テンプレートshowを表示できること" do
          expect(subject).to render_template(:show)
        end
        it "infoオブジェクトが取得できること" do
          subject
          expect(assigns[:info]).to eq(info)
        end
      end
    end
  end
end
