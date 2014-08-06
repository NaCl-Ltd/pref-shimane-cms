require 'spec_helper'

describe Help do
  describe "validate" do
    it { should validate_presence_of :name }
    it { should validate_presence_of :help_category_id }
  end

end
