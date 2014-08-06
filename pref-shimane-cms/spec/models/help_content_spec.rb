require 'spec_helper'

describe HelpContent do
  describe "メソッド" do
    describe "#rename_folder" do
      let(:temp_key) { 'tsfCWwmfwQMcwoWMFmwfoewagneawo' }
      let(:help_file_path) { Rails.root.join('files', 'help', Rails.env) }

      before do
        Dir.mkdir(help_file_path.join(temp_key))
        @help_content = create(:help_content, temp_key: temp_key)
      end

      it "temp_keyのフォルダが削除ないこと" do
        expect(FileTest.exists?(help_file_path.join(temp_key))).to be_false
      end

      it "IDの名前のフォルダがあること" do
        expect(FileTest.exists?(help_file_path.join(@help_content.id.to_s))).to be_true
      end

      after do
        Dir.delete(help_file_path.join(@help_content.id.to_s))
      end
    end
  end
end
