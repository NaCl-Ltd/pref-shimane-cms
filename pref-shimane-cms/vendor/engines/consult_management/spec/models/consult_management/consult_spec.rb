require 'spec_helper'

describe ConsultManagement::Consult do
  describe "バリデーション" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :link }
    it { should validate_presence_of :work_content }
    it { should validate_presence_of :contact }
  end
end
