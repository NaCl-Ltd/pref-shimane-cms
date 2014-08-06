require 'spec_helper'

describe EmergencyInfo do
  describe "validate" do

    context "content blank" do
      subject {
        EmergencyInfo.new(
          display_start_datetime: DateTime.now,
          display_end_datetime:   DateTime.now,
          content: nil
        )
      }
      it { should have(1).errors_on(:content) }
    end

    context "display_start_datetime >= display_end_datetime" do
      subject {
        EmergencyInfo.new(
          display_start_datetime: DateTime.now + 1,
          display_end_datetime:   DateTime.now,
          content: nil
        )
      }
      it { should have(1).errors_on(:display_start_datetime) }
      it { should have(1).errors_on(:display_end_datetime) }
    end
  end

  describe "スコープ" do
    describe "publshes" do
      before do
        s_at = DateTime.now - 1
        e_at = DateTime.now + 1
        create(:emergency_info, display_start_datetime: s_at, display_end_datetime: e_at)
      end

      subject{EmergencyInfo.publishes}

      it "取得されるデータの表示開始日が現在の時間以前であること" do
        expect(subject.all?{|ei|ei.display_start_datetime <= DateTime.now}).to be_true
      end

      it "取得されるデータの表示終了日が現在の時間以降であること" do
        expect(subject.all?{|ei|ei.display_end_datetime >= DateTime.now}).to be_true
      end
    end
  end

  describe 'メソッド' do
    describe ".stop_public" do
      context "データが存在する場合" do
        let(:now) { DateTime.now }

        before do
          create(:emergency_info)
        end

        context "緊急お知らせが公開期間中の場合" do

          before do
            now.stub(:between?).and_return(true)
          end

          it "現在時刻で公開終了時刻を上書きしていること" do
            DateTime.stub(:now).and_return(now)

            EmergencyInfo.stop_public
            expect(EmergencyInfo.first.display_end_datetime.strftime('%Y/%m/%d %H:%M')).to eq(now.strftime('%Y/%m/%d %H:%M'))
          end
        end

        context "緊急お知らせが公開期間でないの場合" do
          before do
            now.stub(:between?).and_return(false)
          end

          it "saveが呼ばれないこと" do
            DateTime.stub(:now).and_return(now)

            EmergencyInfo.stop_public
            expect(EmergencyInfo.any_instance).to_not receive(:save)
          end
        end
      end

      context "データが存在しない場合" do
        it "saveが呼ばれないこと" do
          EmergencyInfo.stop_public

          expect(EmergencyInfo.any_instance).to_not receive(:save)
        end
      end
    end

    describe ".public_info" do
      context "データが存在する場合" do
        before do
          s_at = DateTime.now - 1
          e_at = DateTime.now + 1
          @ei1 = create(:emergency_info, display_start_datetime: s_at, display_end_datetime: e_at)
          @ei2 = create(:emergency_info, display_start_datetime: s_at, display_end_datetime: e_at)
        end

        subject{EmergencyInfo.public_info}

        it "publishesを呼ぶこと" do
          EmergencyInfo.should_receive(:publishes).and_return(EmergencyInfo)
          subject
        end

        it "取得されるデータはIDが大きいものを取得されること" do
          expect(subject).to eq(@ei2)
        end
      end

      context "データが存在しない場合" do
        it "nilが返ること" do
          expect(EmergencyInfo.public_info).to be_nil
        end
      end
    end
  end
end
