require 'spec_helper'


describe Susanoo::Exports::Helpers::PathHelper do
  include Susanoo::Exports::Helpers::PathHelper

  describe "メソッド" do
    describe "#export_path" do
      let(:path) { 'test' }

      before do
        @export_path = Susanoo::Exports::Helpers::PathHelper::EXPORT_PATH.join(path)
      end

      it "export用のパスに変更して返すこと" do
        expect(export_path(path)).to eq(@export_path)
      end

      context "既にexport用のパスである場合" do
        it "変更されないこと" do
          expect(export_path(@export_path)).to eq(@export_path)
        end
      end
    end

    describe "#export_path?" do
      let(:path) { 'test' }

      before do
        @export_path = Susanoo::Exports::Helpers::PathHelper::EXPORT_PATH.join(path)
      end

      context "export用のパスである場合" do
        it "trueを返すこと" do
          expect(export_path?(@export_path)).to be_true
        end
      end

      context "export用のパスでない場合" do
        it "falseを返すこと" do
          expect(export_path?(path)).to be_false
        end
      end
    end

    describe "#base_path" do
      context "pathが'*.html'で終わる場合" do
        let(:path) { '/test/index' }

        it "拡張子をとったパスを返すこと" do
          expect(base_path("#{path}.html")).to eq(path)
        end
      end

      context "pathがディレクトリ名で終わる場合" do
        let(:path) { '/test' }

        it "パスにindexが付与されること" do
          expect(base_path(path)).to eq("#{path}/index")
        end
      end
    end

    describe "#path_with_type" do
      let(:path) { '/test/index' }

      it "指定したタイプの拡張子を付与すること" do
        expect(path_with_type("#{path}.html", :rss)).to eq(Pathname.new("#{path}.rdf"))
      end
    end
  end
end

