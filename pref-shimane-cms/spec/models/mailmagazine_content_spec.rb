require 'spec_helper'

describe MailmagazineContent do
  describe "バリデーション" do
    it { should validate_presence_of :title }
  end
end
