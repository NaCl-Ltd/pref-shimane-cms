require 'spec_helper'

describe Susanoo::Exports::QrCodeCreator do
  describe "メソッド" do
    describe "#initialize" do
      let(:path) { '/path/' }

      before do
        @qr_code_creator = Susanoo::Exports::QrCodeCreator.new(path)
      end

      it "@pathに正しい値が設定されていること" do
        expect(@qr_code_creator.instance_eval{ @path }).to eq(path)
      end
    end

    describe "#make" do
      let(:path) { '/index.html' }
      let(:qr_path) { Pathname.new('/index.png') }

      context "ファイルが存在しない場合" do
        before do
          export_qr_path = Settings.export.docroot + qr_path.to_s
          File.delete(export_qr_path) if File.exist?(export_qr_path)
          @qr_code_creator = Susanoo::Exports::QrCodeCreator.new(path)
          @qr_code = RQRCode::QRCode.new(path, size: 4, level: :h)
        end

        it "QRコードを書き込んでいること" do
          expect_any_instance_of(Susanoo::Exports::QrCodeCreator).to receive(:write_file).with(qr_path, @qr_code.to_img.to_s)
          @qr_code_creator.make
        end
      end

      context "ファイルが存在する場合" do
        before do
          allow(File).to receive(:exists?).and_return(true)
          @qr_code_creator = Susanoo::Exports::QrCodeCreator.new(path)
        end

        it "falseを返すこと" do
          expect(@qr_code_creator.make).to be_false
        end
      end
    end
  end
end

