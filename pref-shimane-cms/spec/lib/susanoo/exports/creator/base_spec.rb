require 'spec_helper'


describe Susanoo::Exports::Creator::Base do
  describe "メソッド" do
    let(:export_dir) { Settings.export.docroot }

    before do
      @base = Susanoo::Exports::Creator::Base.new
    end

    describe "#write_file" do
      let(:path) { '/test/index.html' }
      let(:content) { '<p>test</p>' }

      context "ファイルの中身が変更されている場合" do
        before do
          @base.send(:write_file, path, content)
        end

        it "Export用のフォルダにファイルを書き込むこと" do
          expect(File.read(export_dir + path)).to eq(content)
        end
      end

      context "ファイルの中身が変更されていない場合" do
        before do
          File.open(export_dir + path, 'w') {|f| f.print(content)}
        end

        it "falseが返ること" do
          expect(@base.send(:write_file, path, content)).to be_false
        end
      end
    end

    describe "#copy_file" do
      let(:src_path) { '/index.html' }
      let(:dest_path) { '/to' }

      before do
        File.open(export_dir + src_path, 'w') {|f| f.print('test')}
      end

      before do
        @base.send(:copy_file, src_path, dest_path)
      end

      it "ファイルがコピーされていること" do
        expect(File.exist?(export_dir + dest_path + src_path)).to be_true
      end

      after do
        FileUtils.rm_rf(export_dir + dest_path)
        File.delete(export_dir + src_path)
      end
    end

    describe "#remove_file" do
      let(:src_path) { '/index.html' }

      before do
        File.open(export_dir + src_path, 'w') {|f| f.print('test')}
        @base.send(:remove_file, src_path)
      end

      it "ファイルが削除されていること" do
        expect(File.exist?(export_dir + src_path)).to be_false
      end
    end

    describe "#remove_rf" do
      let(:src_path) { '/index.html' }
      let(:src_dir) { '/genre1' }

      before do
        FileUtils.mkdir_p(export_dir + src_dir)
        File.open(export_dir + src_dir + src_path, 'w') {|f| f.print('test')}
        @base.send(:remove_rf, [src_dir + src_path])
      end

      it "ファイルが削除されていること" do
        expect(File.exist?(export_dir + src_path)).to be_false
      end
    end

    describe "#mv_file" do
      let(:src_path) { '/index.html' }
      let(:dest_path) { '/to' }

      before do
        File.open(export_dir + src_path, 'w') {|f| f.print('test')}
      end

      context '移動元と移動先が異なる場合' do
        before do
          @base.send(:mv_file, [src_path], dest_path)
        end

        it "ファイルが移動されていること" do
          expect(File.exist?(export_dir + dest_path + src_path)).to be_true
        end

        it "元のファイルが存在しないこと" do
          expect(File.exists?(export_dir + src_path)).to be_false
        end
      end

      context '移動元と移動先が同じ場合' do
        let(:dest_path) { src_path }

        before do
          @base.send(:mv_file, [src_path], dest_path)
        end

        it "ファイルが移動されていないこと" do
          expect(File.exist?(export_dir + src_path)).to be_true
        end
      end

      after do
        FileUtils.rm_rf(export_dir + dest_path)
      end
    end


  end
end

