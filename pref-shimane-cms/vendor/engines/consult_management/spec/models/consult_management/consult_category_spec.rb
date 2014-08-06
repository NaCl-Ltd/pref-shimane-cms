require 'spec_helper'

describe ConsultManagement::ConsultCategory do
  describe "バリデーション" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :description }
  end
end
