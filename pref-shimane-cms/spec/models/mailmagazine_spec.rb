require 'spec_helper'

describe Mailmagazine do
  describe "バリデーション" do
    describe 'validate_format_of' do
      subject { create(:mailmagazine) }
      it { should allow_value("abcdefg@#{Settings.mailmagazine.domain}").for(:mail_address) }
      it { should_not allow_value("abcdefg@#{Settings.mailmagazine.domain}aaa").for(:mail_address) }
    end
  end
end
