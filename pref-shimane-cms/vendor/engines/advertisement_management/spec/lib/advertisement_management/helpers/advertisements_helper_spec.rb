require 'spec_helper'

include AdvertisementManagement::Helpers::AdvertisementsHelper

describe "AdvertisementManagement::Helpers::AdvertisementsHelper" do
  describe "advertisement_job_exists?" do
    context "Jobテーブルにaction=move_banner_imagesのレコードがある場合" do
      before do
        create(:job, action: "move_banner_images")
      end

      subject{advertisement_job_exists?}

      it "trueが返ること" do
        expect(subject).to be true
      end
    end

    context "Jobテーブルにaction=move_banner_imagesのレコードがない場合" do
      subject{advertisement_job_exists?}

      it "falseが返ること" do
        expect(subject).to be false
      end
    end
  end
end
