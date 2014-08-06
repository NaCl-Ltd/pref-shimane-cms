require 'spec_helper'

describe Advertisement do
  describe "スコープ" do
    before do
      Advertisement::STATE.keys.each do |state|
        3.times do
          create(:pref_advertisement_list, state: state)
          create(:corp_advertisement_list, state: state)
        end
      end
    end

    describe "published" do
      it "state=PUBLISHED(2)のみ取得されること" do
        expect(AdvertisementList.published.all?{|a|a.state == Advertisement::PUBLISHED}).to be_true
      end
    end
  end

  describe "メソッド" do
    describe ".pref_published" do
      before do
        2.times do
          create(:pref_advertisement_list)
          create(:corp_advertisement_list)
        end
      end
      
      it "関連するAdvertisementのstateが公開のものが取得されること" do
        expect(AdvertisementList.pref_published.all?{|al|al.state == Advertisement::PUBLISHED}).to be_true
      end

      it "pref_ad_numberの昇順で取得されていること" do
        lists = AdvertisementList.pref_published.sort_by{|al|al.pref_ad_number}
        expect(AdvertisementList.pref_published).to eq(lists)
      end
    end

    describe ".corp_published" do
      before do
        2.times do
          create(:pref_advertisement_list)
          create(:corp_advertisement_list)
        end
      end

      it "関連するAdvertisementのstateが公開のものが取得されること" do
        expect(AdvertisementList.corp_published.all?{|al|al.state == Advertisement::PUBLISHED}).to be_true
      end

      it "corp_ad_numberの昇順で取得されていること" do
        lists = AdvertisementList.corp_published.sort_by{|al|al.corp_ad_number}
        expect(AdvertisementList.corp_published).to eq(lists)
      end
    end

    describe ".set_preview_lists" do
      before do
        Advertisement::SIDE_TYPE.keys.each do |st|
          3.times do
            create(:pref_advertisement_list, state: Advertisement::PUBLISHED)
            create(:corp_advertisement_list, state: Advertisement::PUBLISHED)
          end
        end
      end

      context "戻り値１について" do
        subject{AdvertisementList.set_preview_lists[0]}

        it "配列であること" do
          expect(subject).to be_kind_of(Array)
        end

        it "配列の要素がAdvertisementのインスタンスであること" do
          expect(subject.first).to be_kind_of(Advertisement)
        end

        it "配列の要素がAdvertisementの新規インスタンスであること" do
          expect(subject.first.new_record?).to be_true
        end

        it "AdvertisementList.pref_publishedで取得したレコードをもとに値がつくられていること" do
          als = AdvertisementList.pref_published
          subject.zip(als).all? do |pref, al|
            pref.state == al.state && pref.pref_ad_number == al.pref_ad_number && pref.corp_ad_number == al.corp_ad_number
          end
        end
      end

      context "戻り値2について" do
        subject{AdvertisementList.set_preview_lists[1]}

        it "配列であること" do
          expect(subject).to be_kind_of(Array)
        end

        it "配列の要素がAdvertisementのインスタンスであること" do
          expect(subject.first).to be_kind_of(Advertisement)
        end

        it "配列の要素がAdvertisementの新規インスタンスであること" do
          expect(subject.first.new_record?).to be_true
        end

        it "AdvertisementList.corp_publishedで取得したレコードをもとに値がつくられていること" do
          als = AdvertisementList.corp_published
          subject.zip(als).all? do |corp, al|
            corp.state == al.state && corp.pref_ad_number == al.pref_ad_number && corp.corp_ad_number == al.corp_ad_number
          end
        end
      end
    end
  end
end
