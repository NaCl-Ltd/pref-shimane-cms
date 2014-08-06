require 'spec_helper'

describe Division do
  describe "バリデーション" do
    it { should validate_presence_of :name }
  end

  describe "スコープ" do
    describe "enables" do
      it "enable=trueのものが取得されること" do
        create(:division)
        expect(Division.enables.all?(&:enable)).to be_true
      end
    end
  end

  describe "メソッド" do
    describe "#enable_label" do
      it "self.enable=trueの場合、正しい文字列が返ること" do
        label = I18n.t("activerecord.attributes.division.enable_label.enable")
        expect(Division.new(enable: true).enable_label).to eq(label)
      end

      it "self.enable=falseの場合、正しい文字列が返ること" do
        label = I18n.t("activerecord.attributes.division.enable_label.disable")
        expect(Division.new(enable: false).enable_label).to eq(label)
      end
    end
  end
end
