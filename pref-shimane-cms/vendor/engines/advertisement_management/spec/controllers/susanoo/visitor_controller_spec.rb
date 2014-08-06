require 'spec_helper'

describe Susanoo::VisitorsController do
  describe "アクション" do
    describe "GET attach_file" do
      describe "正常系" do
        context "広告画像の場合" do
          let(:file_name) { 'rails.png' }
          let(:file_path){ "#{Rails.root}#{Advertisement::IMAGE_DIR}/#{file_name}" }

          before do
            request.path = "/advertisement.data/#{file_name}"
            get :attach_file
          end
        end
      end
    end

    describe "#set_advertisement" do
      let!(:published_pref)   { create(:published_pref_advertisement) }
      let!(:published_corp)   { create(:published_corp_advertisement) }
      let!(:unpublished_pref) { create(:unpublished_pref_advertisement) }
      let!(:unpublished_corp) { create(:unpublished_corp_advertisement) }

      before do
        controller.send(:set_advertisement)
      end

      it "@pref_adsに正しい値がセットされていること" do
        expect(assigns[:pref_ads]).to eq [published_pref]
      end

      it "@corp_adsに正しい値がセットされていること" do
        expect(assigns[:corp_ads]).to eq [published_corp]
      end
    end
  end
end

