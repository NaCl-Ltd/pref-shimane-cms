require 'spec_helper'

describe AdvertisementManagement::Susanoo::Export do
  describe "メソッド" do
    let(:export) { Susanoo::Export.new }

    before do
      allow_any_instance_of(Susanoo::Exports::Creator::Base).to receive(:sync)
    end

    describe ".action_methods" do
      it "Export処理のアクションが登録されていること" do
        expect(Susanoo::Export.action_methods.to_a).to include(*%w[
          move_banner_images
        ])
      end
    end


    describe "#move_banner_images" do
      it "BannerCreatorでバナーをmakeしていること" do
        expect_any_instance_of(AdvertisementManagement::Susanoo::Exports::BannerCreator).to receive(:make)
        export.move_banner_images
      end
    end
  end
end
