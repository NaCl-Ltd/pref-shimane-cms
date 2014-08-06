require 'spec_helper'

describe EngineMaster do
  describe "バリデーション" do
  	it {should validate_presence_of :name}
  	it {should validate_uniqueness_of :name}
  end

  describe "メソッド" do
  	describe ".enable?" do
  		context "引数で渡したエンジン名のレコードがある場合" do
  			it "enableがTrueのときtrueを返すこと" do
  				e = create(:engine_master, name: "a", enable: true)
  				expect(EngineMaster.enable?(e.name)).to be_true
  			end

  			it "enableがFalseのときfalseを返すこと" do
  				e = create(:engine_master, name: "a", enable: false)
  				expect(EngineMaster.enable?(e.name)).to be_false
  			end
			end

			it "引数で渡したエンジン名のレコードがない場合、falseを返すこと" do
				EngineMaster.destroy_all
				expect(EngineMaster.enable?("a")).to be_false
			end
  	end

  	describe ".engine_classes" do
  		it "エンジンクラスを配列で返すこと" do
  			str = "example"
  			EngineMaster.stub(:constantize_engine).and_return(Rails::Engine)
  			array = [str]
  			Dir.stub(:glob).and_return(array)
  			expect(EngineMaster.engine_classes).to eq([Rails::Engine])
  		end
  	end

  	describe ".constantize_engine" do
  		it "存在するエンジン名を引数で渡した場合、エンジンクラスが返ること" do
  			expect(EngineMaster.constantize_engine("rails")).to eq(Rails::Engine)
  		end

  		it "存在しないエンジン名を引数で渡した場合、nilが返ること" do
  			expect(EngineMaster.constantize_engine("aaa")).to be_nil
  		end
  	end

  	describe "#enable_label" do
  		it "enableがtrueの場合、該当する文字列を返すこと" do
  			label = I18n.t("activerecord.attributes.engine_master.enable_label.enable")
  			expect(EngineMaster.new(enable: true).enable_label).to eq(label)
  		end

  		it "enableがfalseの場合、該当する文字列を返すこと" do
  			label = I18n.t("activerecord.attributes.engine_master.enable_label.disable")
  			expect(EngineMaster.new(enable: false).enable_label).to eq(label)
  		end
  	end
  end
end
