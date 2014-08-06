require 'spec_helper'

describe ConsultManagement::Susanoo::Export do
  describe ".create_consult_json" do
    it "JsonCreatorでJSONファイルをmakeしていること" do
      expect_any_instance_of(ConsultManagement::Susanoo::Exports::JsonCreator).to receive(:make)
      Susanoo::Export.new.create_consult_json
    end
  end
end

