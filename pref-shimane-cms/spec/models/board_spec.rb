require 'spec_helper'

describe Board do
  describe "バリデーション" do
    it { should validate_presence_of :title }
  end

  describe "メソッド" do
    describe "#accessible?" do
      let(:board){create(:board)}
      let(:section_id){board.section_id}
      let(:user){create(:user)}

      subject{board.accessible?(user)}

      it "ログインユーザが運用管理者の場合、trueが返ること" do
        User.any_instance.stub(:admin?).and_return(true)
        expect(subject).to be_true
      end

      context "ログインユーザが運用管理者以外の場合" do
        before{User.any_instance.stub(:admin?).and_return(false)}

        it "掲示板の所属がユーザの所属と等しい場合、trueが返ること" do
          User.any_instance.stub(:section_id).and_return(section_id)
          Board.any_instance.stub(:section_id).and_return(section_id)
          expect(subject).to be_true
        end

        it "掲示板の所属がユーザの所属と等しくない場合、falseが返ること" do
          User.any_instance.stub(:section_id).and_return(1)
          Board.any_instance.stub(:section_id).and_return(2)
          expect(subject).to be_false
        end
      end
    end
  end
end
