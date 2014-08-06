require 'spec_helper'

describe Advertisement do
  describe "バリデーション" do
    it { should validate_presence_of(:side_type).with_message(I18n.t("activerecord.errors.messages.non_select")) }
    it { should validate_presence_of :name }
    it { should validate_uniqueness_of :name }
    it { should validate_presence_of :alt }
  end

  describe "スコープ" do
    before do
      Advertisement::STATE.keys.each do |state|
        Advertisement::SIDE_TYPE.keys.each do |st|
          3.times do
            create(:pref_advertisement, side_type: st, state: state)
            create(:corp_advertisement, side_type: st, state: state)
          end
        end
      end
    end

    describe "insides" do
      subject{Advertisement.insides}
      it "side_type=INSIDE_TYPE(1)のみ取得されること" do
        expect(subject.all?{|a|a.side_type == Advertisement::INSIDE_TYPE}).to be true
      end
    end

    describe "outsides" do
      subject{Advertisement.outsides}
      it "side_type=OUTSIDE_TYPE(2)のみ取得されること" do
        expect(subject.all?{|a|a.side_type == Advertisement::OUTSIDE_TYPE}).to be true
      end
    end

    describe "publishes" do
      subject{Advertisement.publishes}
      it "state=PUBLISHED(2)のみ取得されること" do
        expect(subject.all?{|a|a.state == Advertisement::PUBLISHED}).to be true
      end
    end

    describe "not_publishes" do
      subject{Advertisement.not_publishes}
      it "state=NOT_PUBLISHED(1)のみ取得されること" do
        expect(subject.all?{|a|a.state == Advertisement::NOT_PUBLISHED}).to be true
      end
    end
  end

  describe "メソッド" do
    describe "#validate_begin_date_and_end_date" do
      context "begin_dateよりend_dateが過去の場合" do
        subject do
          ad = Advertisement.new(begin_date: DateTime.now, end_date: (DateTime.now-1))
          ad.validate_begin_date_and_end_date
          ad
        end
        it { should have(1).errors_on(:begin_date) }
      end
    end

    describe ".pref_advertisements" do
      before do
        Advertisement::SIDE_TYPE.keys.each do |st|
          3.times do
            create(:pref_advertisement, side_type: st)
            create(:corp_advertisement, side_type: st)
          end
        end
      end

      subject{Advertisement.pref_advertisements}
      it "side_type=INSIDE_TYPE(1)のみ取得されること" do
        expect(subject.all?{|a|a.side_type == Advertisement::INSIDE_TYPE}).to be true
      end

      it "取得されたレコードが状態（state）の降順、県番号（pref_ad_number）の昇順であること" do
        lists = subject.sort{|a, b|[b.state, a.pref_ad_number] <=> [a.state, b.pref_ad_number]}
        expect(subject).to eq(lists)
      end
    end

    describe ".corp_advertisements" do
      before do
        Advertisement::SIDE_TYPE.keys.each do |st|
          3.times do
            create(:pref_advertisement, side_type: st)
            create(:corp_advertisement, side_type: st)
          end
        end
      end

      subject{Advertisement.corp_advertisements}
      it "side_type=OUTSIDE_TYPE(2)のみ取得されること" do
        expect(subject.all?{|a|a.side_type == Advertisement::OUTSIDE_TYPE}).to be true
      end

      it "取得されたレコードが状態（state）の降順、企業番号（corp_ad_number）の昇順であること" do
        lists = subject.sort{|a, b|[b.state, a.corp_ad_number] <=> [a.state, b.corp_ad_number]}
        expect(subject).to eq(lists)
      end
    end

    describe '#published?' do
      it "state=PUBLISHED(2)のとき、trueが返ること" do
        publish = create(:pref_advertisement, state: Advertisement::PUBLISHED)
        expect(publish.published?).to be true
      end

      it "state=unpuBLISHED(1)のとき、falseが返ること" do
        unpublish = create(:pref_advertisement, state: Advertisement::NOT_PUBLISHED)
        expect(unpublish.published?).to be false
      end
    end

    describe '#unpublished?' do
      it "state=PUBLISHED(2)のとき、falseが返ること" do
        publish = create(:pref_advertisement, state: Advertisement::PUBLISHED)
        expect(publish.unpublished?).to be false
      end

      it "state=NOT_PUBLISHED(1)のとき、trueが返ること" do
        unpublish = create(:pref_advertisement, state: Advertisement::NOT_PUBLISHED)
        expect(unpublish.unpublished?).to be true
      end
    end

    describe '#expired?' do
      it "end_dateが現在時刻より昔の場合、trueを返す。" do
        ad = create(:pref_advertisement, begin_date: DateTime.now-2, end_date: (DateTime.now-1))
        ad.expired?.should be_true
      end
    end

    describe '#pref?' do
      it "side_type=INSIDE_TYPE(1)のとき、trueが返ること" do
        ad = create(:pref_advertisement, side_type: Advertisement::INSIDE_TYPE)
        expect(ad.pref?).to be true
      end

      it "side_type=OUTSIDE_TYPE(2)のとき、falseが返ること" do
        ad = create(:pref_advertisement, side_type: Advertisement::OUTSIDE_TYPE)
        expect(ad.pref?).to be false
      end
    end

    describe '#corp?' do
      it "side_type=INSIDE_TYPE(1)のとき、falseが返ること" do
        ad = create(:pref_advertisement, side_type: Advertisement::INSIDE_TYPE)
        expect(ad.corp?).to be false
      end

      it "side_type=OUTSIDE_TYPE(2)のとき、trueが返ること" do
        ad = create(:pref_advertisement, side_type: Advertisement::OUTSIDE_TYPE)
        expect(ad.corp?).to be true
      end
    end

    describe '#state_label' do
      it "stateに合った状態名が返ること" do
        ad = create(:pref_advertisement)
        str = I18n.t("activerecord.attributes.advertisement.state_label.#{Advertisement::STATE[ad.state]}")
        expect(ad.state_label).to eq(str)
      end
    end

    describe '#show_in_header_label' do
      it "広告名の有無が文字列で返ること" do
        ad = create(:pref_advertisement)
        flg = !!ad.show_in_header
        str = I18n.t("activerecord.attributes.advertisement.show_in_header_label.#{Advertisement::SHOW_IN_HEADER[flg]}")
        expect(ad.show_in_header_label).to eq(str)
      end
    end

    describe '#side_type_label' do
      it "side_typeに合った状態名が返ること" do
        ad = create(:pref_advertisement)
        str = I18n.t("activerecord.attributes.advertisement.side_type_label.#{Advertisement::SIDE_TYPE[ad.side_type]}")
        expect(ad.side_type_label).to eq(str)
      end
    end

    describe '#delete_img' do
      it "画像が削除されていること" do
        ad = create(:pref_advertisement)
        ad.delete_img
        expect(File.exists?(ad.image.path)).to be false
      end
    end

    describe '.resetting_list' do
      before do
        3.times do
          create(:pref_advertisement_list)
          create(:corp_advertisement_list)
        end
      end

      subject{Advertisement.resetting_list}
      it "AdvertisementListレコードが全て削除されていること" do
        ids = AdvertisementList.all.map(&:id)
        subject
        expect(AdvertisementList.where("id IN (?)", ids).count).to be_zero
      end

      it "全てのAdvertisementにひもづくAdvetisementListレコードが生成されること" do
        subject
        ads = Advertisement.all
        expect(ads.all?{|ad|ad.advertisement_list.present?}).to be true
      end

      it "作成されたAdvertisementListのstateがAdvertisementと等しいこと" do
        subject
        ads = Advertisement.all
        expect(ads.all?{|ad|ad.advertisement_list.state == ad.state}).to be true
      end

      it "作成されたAdvertisementListのpref_ad_numberがAdvertisementと等しいこと" do
        subject
        ads = Advertisement.all
        expect(ads.all?{|ad|ad.advertisement_list.pref_ad_number == ad.pref_ad_number}).to be true
      end

      it "作成されたAdvertisementListのcorp_ad_numberがAdvertisementと等しいこと" do
        subject
        ads = Advertisement.all
        expect(ads.all?{|ad|ad.advertisement_list.corp_ad_number == ad.corp_ad_number}).to be true
      end
    end

    describe '#display_public_image_path' do
      it "画像の表示用のパスが返ること" do
        ad = create(:pref_advertisement)
        str = File.join(Advertisement::DISPLAY_PUBLIC_IMAGE_DIR_PATH, ad.id.to_s + File.extname(ad.image.path))
        expect(ad.display_public_image_path).to eq(str)
      end
    end

    describe '.advertisement_job_exists?' do
      context "jobsテーブルに広告用のJobが存在する場合" do
        before do
          create(:job, action: "move_banner_images")
        end

        it "true が返ること" do
          expect(Advertisement.advertisement_job_exists?).to be true
        end
      end

      context "Jobテーブルにaction=move_banner_imagesのレコードがない場合" do
        before do
          Job.where(action: "move_banner_images").delete_all
        end

        it "false が返ること" do
          expect(Advertisement.advertisement_job_exists?).to be false
        end
      end
    end

    describe '.state_editable?' do
      context "jobsテーブルに広告用のJobが存在する場合" do
        before { create(:job, action: "move_banner_images") }

        context "トップページ上部のバナーが未登録の場合" do
          before { Advertisement.toppages.delete_all }

          it "false が返ること" do
            expect(Advertisement.state_editable?).to be false
          end
        end

        context "トップページ上部のバナーが登録済の場合" do
          before { create(:unpublished_toppage_advertisement) }

          it "false が返ること" do
            expect(Advertisement.state_editable?).to be false
          end
        end
      end

      context "Jobテーブルにaction=move_banner_imagesのレコードがない場合" do
        before do
          Job.where(action: "move_banner_images").delete_all
        end

        context "トップページ上部のバナーが未登録の場合" do
          before { Advertisement.toppages.delete_all }

          it "false が返ること" do
            expect(Advertisement.state_editable?).to be false
          end
        end

        context "トップページ上部のバナーが登録済の場合" do
          before { create(:unpublished_toppage_advertisement) }

          it "false が返ること" do
            expect(Advertisement.state_editable?).to be true
          end
        end
      end
    end


    describe '.send_expired_advertisement_mail' do
      before do
        ActionMailer::Base.delivery_method = :test
        ActionMailer::Base.perform_deliveries = true
        ActionMailer::Base.deliveries = []

        create(:pref_advertisement, begin_date: DateTime.now-2, end_date: (DateTime.now-1))
      end

      it 'メールが送信されること' do
        Advertisement.send_expired_advertisement_mail
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    end
  end
end
