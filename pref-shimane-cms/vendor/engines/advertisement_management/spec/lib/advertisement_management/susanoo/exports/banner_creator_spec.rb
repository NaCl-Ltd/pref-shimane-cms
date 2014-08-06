require 'spec_helper'

describe AdvertisementManagement::Susanoo::Exports::BannerCreator do
  describe "メソッド" do
    before do
      allow_any_instance_of(Susanoo::Exports::Creator::Base).to receive(:rsync)
    end

    describe "#initialize" do
      let!(:advertisement_list) { [create(:advertisement_list1, state: Advertisement::PUBLISHED)] }

      before do
        @banner_creator = AdvertisementManagement::Susanoo::Exports::BannerCreator.new
      end

      it "@advertisement_listsに正しい値を設定していること" do
        expect(@banner_creator.instance_eval{ @advertisement_lists }).to eq(advertisement_list)
      end

      it "@image_dest_dirに正しい値を設定していること" do
        expect(@banner_creator.instance_eval{ @image_dest_dir }).to eq(Settings.export.advertisement.image_dir)
      end

      it "@javascript_file_pathに正しい値を設定していること" do
        expect(@banner_creator.instance_eval{ @javascript_file_path }).to eq(Settings.export.advertisement.javascript_file_path)
      end
    end

    describe "#make" do
      let(:banner_creator) { AdvertisementManagement::Susanoo::Exports::BannerCreator.new }

      it "#copy_advertisementメソッドを呼び出していること" do
        expect(banner_creator).to receive(:copy_advertisement)
        banner_creator.make
      end

      it "#remove_unknown_fileメソッドを呼び出していること" do
        expect(banner_creator).to receive(:remove_unknown_file)
        banner_creator.make
      end

      it "#make_javascriptメソッドを呼び出していること" do
        expect(banner_creator).to receive(:make_javascript)
        banner_creator.make
      end

      it "#update_advertisementメソッドを呼び出していること" do
        expect(banner_creator).to receive(:update_advertisement)
        banner_creator.make
      end

      context "TOPページが存在する場合" do
        let(:top_genre) { create(:top_genre) }
        let!(:page) { create(:page, name: 'index', genre_id: top_genre.id) }

        it "PageCreator#makeを呼び出していること" do
          expect_any_instance_of(Susanoo::Exports::PageCreator).to receive(:make)
          banner_creator.make
        end
      end
    end

    describe "#copy_advertisement" do
      let!(:advertisement_list) { [create(:advertisement_list1, state: Advertisement::PUBLISHED)] }
      let(:banner_creator) { AdvertisementManagement::Susanoo::Exports::BannerCreator.new }

      before do
        @dest_dir = banner_creator.instance_eval{ @image_dest_dir }
      end

      it "#copy_fileメソッドを正しく実行していること" do
        image_paths = advertisement_list.map{|a_l| a_l.advertisement.image.path}

        expect(banner_creator).to receive(:copy_file).with(image_paths, @dest_dir, {}, src_convert: false)
        banner_creator.copy_advertisement
      end

      it "#sync_docrootメソッドを正しく実行していること" do
        sync_dir = "#{File.dirname(@dest_dir)}/"
        expect(banner_creator).to receive(:sync_docroot).with(sync_dir)
        banner_creator.copy_advertisement
      end
    end

    describe "#make_javascript" do
      context "公開設定のAdvertisementListレコードが存在する場合" do
        let(:advertisement_list) { [create(:published_corp_advertisement_list, state: Advertisement::PUBLISHED)] }
        let(:banner_creator) { AdvertisementManagement::Susanoo::Exports::BannerCreator.new }

        before do
          dest_dir = banner_creator.instance_eval{ @image_dest_dir }
          @javascript_file_path = banner_creator.instance_eval{ @javascript_file_path }

          @content = []
          advertisement_list.each do |a_l|
            ad = a_l.advertisement
            @content << {
              url: ad.url,
              alt: ad.alt,
              image: "#{dest_dir}#{File.basename(ad.image.path)}"
            }
          end
        end

        it "正しい内容で書き込んでいること" do
          expect(banner_creator).to receive(:write_file).with(@javascript_file_path, "BANNERS = #{JSON.generate(@content)}")
          banner_creator.make_javascript
        end

        it "#syncメソッドを正しく実行していること" do
          expect(banner_creator).to receive(:sync_docroot).with(@javascript_file_path)
          banner_creator.make_javascript
        end
      end
    end

    describe "#update_advertisement" do
      let(:a_l) { create(:advertisement_list1, state: Advertisement::PUBLISHED) }
      let(:banner_creator) { AdvertisementManagement::Susanoo::Exports::BannerCreator.new }

      before do
        @advertisement = a_l.advertisement
        banner_creator.send(:update_advertisement)
        @advertisement.reload
      end

      it "Advertisementレコードのstateカラムが更新されること" do
        expect(@advertisement.state).to eq(a_l.state)
      end

      it "Advertisementレコードのpref_ad_numberカラムが更新されること" do
        expect(@advertisement.pref_ad_number).to eq(a_l.pref_ad_number)
      end

      it "Advertisementレコードのcorp_ad_numberカラムが更新されること" do
        expect(@advertisement.corp_ad_number).to eq(a_l.corp_ad_number)
      end

      it "AdvertisementListが空になること" do
        expect(AdvertisementList.count).to eq(0)
      end
    end
  end
end

