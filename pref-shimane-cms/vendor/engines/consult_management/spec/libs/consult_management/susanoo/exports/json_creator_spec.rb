require 'spec_helper'

describe ConsultManagement::Susanoo::Exports::JsonCreator do
  describe "#initialize" do
    let!(:consults) { [ create(:consult) ] }

    before do
      @json_creator = ConsultManagement::Susanoo::Exports::JsonCreator.new
    end

    it "consultを全件セットしていること" do
      expect(@json_creator.instance_eval{ @consults }).to eq(consults)
    end
  end

  describe "#make" do

    let!(:consults) do
      create(:consult)
      ConsultManagement::Consult.select(:id, :name, :link, :work_content, :contact)
    end

    before do
      @json_creator = ConsultManagement::Susanoo::Exports::JsonCreator.new
      @json = consults.map{|c| c.attributes.merge(consult_category_ids: c.consult_categories.pluck(:id))}.to_json
      @path = File.join(Settings.consult_management.data.dir, Settings.consult_management.data.json.path)
      allow_any_instance_of(::Susanoo::Exports::Creator::Base).to receive(:sync_docroot)
    end

    it "正しいデータをJSONファイルに書き込んでいること" do
      expect_any_instance_of(ConsultManagement::Susanoo::Exports::JsonCreator).to receive(:write_file).with(
        @path,
        @json
      )
      @json_creator.make
    end

    it "正しくJSONファイルを同期させていること" do
      expect(@json_creator).to receive(:sync_docroot).with(@path)
      @json_creator.make
    end
  end
end

