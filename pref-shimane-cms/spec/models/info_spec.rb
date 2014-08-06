require 'spec_helper'

describe Info do

  describe "validate" do
    it { should validate_presence_of :title }
    it { should validate_presence_of :content }
    it { should ensure_length_of(:title).is_at_least(1).is_at_most(20) }
  end

end
