require 'spec_helper'

describe "Susanoo::Assets::HelpImage" do
  subject { Susanoo::Assets::HelpImage.new }

  describe "メソッド" do
    describe "#data_file_size" do
      context 'ファイルサイズが上限以下の場合' do
        before do
          allow(subject).to receive(:data_file_size).and_return(Settings.max_upload_image_size)
        end

        it '戻り値は true であること' do
          expect(subject.validate_image_size).to be_true
        end

        it 'messages は空であること' do
          subject.validate_image_size
          expect(subject.messages).to have(:no).items
        end
      end

      context 'ファイルサイズが上限を超えた場合' do
        before do
          Settings.max_upload_image_size = 50.kilobytes
          allow(subject).to receive(:data_file_size).and_return(Settings.max_upload_image_size + 1)
        end
        after do
          Settings.reload!
        end

        it '戻り値は false であること' do
          expect(subject.validate_image_size).to be_false
        end

        it 'messages にメッセージが追加されること' do
          subject.validate_image_size
          expect(subject.messages).to match_array([
            I18n.t('shared.upload.image_size_too_big', size: '50k')
          ])
        end
      end
    end

    describe "#validate_total_image_size" do
      context 'ファイル合計サイズが上限以下の場合' do
        before do
          allow(subject).to receive(:data_file_size).and_return(1)
          allow(subject).to receive(:total_image_size).and_return(Settings.max_upload_image_total_size - 1)
        end

        it '戻り値は true であること' do
          expect(subject.validate_total_image_size).to be_true
        end

        it 'messages は空であること' do
          subject.validate_total_image_size
          expect(subject.messages).to have(:no).items
        end
      end

      context 'ファイルサイズが上限を超えた場合' do
        before do
          Settings.max_upload_image_total_size = 3.megabytes
          allow(subject).to receive(:data_file_size).and_return(1)
          allow(subject).to receive(:total_image_size).and_return(Settings.max_upload_image_total_size)
        end
        after do
          Settings.reload!
        end

        it '戻り値は false であること' do
          expect(subject.validate_total_image_size).to be_false
        end

        it 'messages にメッセージが追加されること' do
          subject.validate_total_image_size
          expect(subject.messages).to match_array([
            I18n.t('shared.upload.image_total_size_too_big', size: '3M')
          ])
        end
      end
    end

    describe "#number_to_human_size" do
      context '50.kilobyte を指定する場合' do
        it '50k が返ること' do
          expect(subject.send(:number_to_human_size, 50.kilobytes)).to eq '50k'
        end
      end

      context '3.megabytes を指定する場合' do
        it '3M が返ること' do
          expect(subject.send(:number_to_human_size, 3.megabytes)).to eq '3M'
        end
      end

      context '3.5.megabytes を指定する場合' do
        it '4M が返ること' do
          expect(subject.send(:number_to_human_size, 3.5.megabytes)).to eq '4M'
        end
      end
    end
  end
end
