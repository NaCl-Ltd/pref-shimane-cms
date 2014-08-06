require 'spec_helper'

describe PageTemplate do
  describe "バリデーション" do
    subject { create(:page_template) }

    it { should validate_presence_of :name }
    it { should validate_uniqueness_of :name }
    it { should validate_presence_of :content }
  end
end
