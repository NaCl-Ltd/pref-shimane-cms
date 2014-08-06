require 'spec_helper'

describe LostLink do
  describe "スコープ" do
    describe "insides" do
      before do
        create(:lost_link, side_type: LostLink::INSIDE_TYPE)
        create(:lost_link, side_type: LostLink::OUTSIDE_TYPE)
      end

      subject{LostLink.insides}

      it "side_type=INSIDE_TYPEのものが取得されること" do
        expect(subject.all?{|l|l.side_type == LostLink::INSIDE_TYPE})
      end
    end

    describe "outsides" do
      before do
        create(:lost_link, side_type: LostLink::INSIDE_TYPE)
        create(:lost_link, side_type: LostLink::OUTSIDE_TYPE)
      end

      subject{LostLink.outsides}

      it "side_type=OUTSIDE_TYPEのものが取得されること" do
        expect(subject.all?{|l|l.side_type == LostLink::OUTSIDE_TYPE})
      end
    end

    describe "manages" do
      let(:section_id){1}
      before do
        create(:lost_link, section_id: section_id)
        create(:lost_link, section_id: 2)
        User.any_instance.stub(:section_id).and_return(section_id)
      end

      let(:user){create(:user)}
      subject{LostLink.manages(user)}

      it "section_id=user.sectionのレコードが取得出来ること" do
        expect(subject.all?{|l|l.section_id == section_id})
      end
    end
  end
end
