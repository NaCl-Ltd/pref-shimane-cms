require 'spec_helper'

describe BoardComment do
  describe "バリデーション" do
    it { should validate_presence_of :from }
    it { should validate_presence_of :body }
    it { should validate_presence_of(:board_id).with_message("の掲示板が見つかりません") }
  end

  describe "callback" do
    describe "before_save" do
      let(:board_comment){create(:board_comment)}
      it "normalize_newlinesが呼ばれていること" do
        board_comment.stub(:valid?).and_return(true)
        board_comment.should_receive(:normalize_newlines)
        board_comment.save
      end
    end
  end

  describe "スコープ" do
    before do
      3.times do 
        create(:board_comment, public: nil)
        create(:board_comment, public: true)
        create(:board_comment, public: false)
      end
    end

    describe "publishes" do
      subject{BoardComment.publishes}

      it "public=trueのものが取得出来ること" do
        subject.each{|bc|expect(bc.public).to be_true}
      end
    end

    describe "unpublishes" do
      subject{BoardComment.unpublishes}

      it "public=trueのものが取得出来ること" do
        subject.each{|bc|expect(bc.public).to be_false}
      end
    end

    describe "nil_publics" do
      subject{BoardComment.nil_publics}

      it "public=trueのものが取得出来ること" do
        subject.each{|bc|expect(bc.public).to be_nil}
      end
    end
  end

  describe "メソッド" do
    describe "#normalize_newlines" do
      let(:before_str){"test\r\ntest\r\ntest"}
      let(:after_str){"test\ntest\ntest"}
      let(:board_comment){create(:board_comment)}

      subject{board_comment.__send__(:normalize_newlines)}

      it "bodyの改行コードが\nに変換されていること" do
        board_comment.body = before_str
        subject
        expect(board_comment.body).to eq(after_str)
      end
    end
  end
end
