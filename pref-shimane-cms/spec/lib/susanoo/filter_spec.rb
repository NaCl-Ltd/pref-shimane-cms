require 'spec_helper'

include Susanoo::Filter

describe "Susanoo::Filter" do
  describe "convert" do
    it "正しく変換できること" do
      converted = convert("あ", 'utf-8', 'euc-jp')
      expect(converted.ord).to eq("A4A2".hex )
    end

    it "不正な文字を含む場合、不正な文字を除いた文字列が返ること" do
      converted = convert("①あ②", 'utf-8', 'euc-jp')
      expect(converted.ord).to eq("A4A2".hex )
    end

    it "ブロックを処理すること" do
      expect(convert("①あ②", 'utf-8', 'euc-jp') { |c|
        "x"
      }).to eq("xあx".encode("euc-jp", "utf-8"))
    end
  end
  
  describe "non_japanese_chars" do
    it "機種依存文字を取り出せること" do
      expect(non_japanese_chars("あ①②")).to eq(["①", "②"])
    end
  end
end
