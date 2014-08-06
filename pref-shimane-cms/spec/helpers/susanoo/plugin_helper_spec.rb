require 'spec_helper'

describe Susanoo::PluginHelper do
  describe "#emergency_exist?" do
    let(:top_genre) { create(:top_genre) }
    let(:emergency_genre) { create(:genre, name: 'emergency', parent: top_genre) }
    let(:page) { create(:page, genre: emergency_genre) }

    context "emergencyのGenreの中に、ニュースのコンテンツがある場合" do
      let!(:section_news) { create(:section_news, path: page.path) }

      it "trueを返すこと" do
        expect(helper.emergency_exist?).to be_true
      end
    end

    context "emergencyのGenreの中に、ニュースのコンテンツがない場合" do
      let!(:page) { create(:page, genre_id: emergency_genre.id) }

      it "falseを返すこと" do
        expect(helper.emergency_exist?).to be_false
      end
    end
  end

  describe "#max_count" do
    context "引数が空配列の場合" do
      let(:args) { [] }

      it "9を返すこと" do
        expect(helper.max_count(args)).to eq(9)
      end
    end

    context "引数が空配列ではない場合" do
      let(:number) { 2 }
      let(:args) { [number] }

      it "配列の最初に格納されている数字 - 1 の数字がとれること" do
        expect(helper.max_count(args)).to eq(number - 1)
      end
    end
  end

  describe "#show_section_news_title?" do
    context "配列に'on'という文字列が含まれている場合" do
      let(:args) { ['on', 'off', 'on'] }

      before do
        @result = helper.show_section_news_title?(args)
      end

      it "trueが返ること" do
        expect(@result).to be_true
      end

      it "配列から'on'という文字列を除外した配列になること" do
        expect(args).to eq(args.reject{|a| a == 'on'})
      end
    end

    context "配列に'on'という文字列が含まれていない場合" do
      let(:args) { ['off'] }

      it "falseが返ること" do
        expect(helper.show_section_news_title?(args)).to be_false
      end
    end
  end
end
