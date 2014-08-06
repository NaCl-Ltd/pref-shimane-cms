require 'spec_helper'

describe SiteComponent do
  describe "バリデーション" do
    it { should validate_uniqueness_of(:name)  }  
  end

  describe "メソッド" do
    describe ".[]" do
      let(:name){"theme"}
      let(:value){"blue"}
      before do
        create(:site_component, name: name, value: value)
      end

      it "引数で渡した値に対応するレコードのvalueが取得されること" do
        expect(SiteComponent[name]).to eq(value)
      end

      it "引数で渡した値に対応するレコードが無い場合、nilを返すこと" do
        expect(SiteComponent["testtest"]).to be_nil
      end
    end

    describe ".[]=" do
      let(:name){"theme"}
      let(:value){"blue"}
      let(:update_value){"green"}
      before do
        create(:site_component, name: name, value: value)
      end

      subject{SiteComponent[name] = update_value}

      it "該当するレコードを引数２の値で更新されること" do
        expect{subject}.to change{SiteComponent.find_by(name: name).value}.from(value).to(update_value)
      end
    end
  end
end
