require 'spec_helper'

class Dummy
  def self.before_save(arg); end;
  include ConsultManagement::Concerns::AddJob
end


describe ConsultManagement::Concerns::AddJob do
  describe "#add_job" do
    subject{ Dummy.new.send(:add_job) }

    context "Jobが存在しない場合" do
      before do
        Job.where(action: ConsultManagement::Concerns::AddJob::JOB_ACTION).destroy_all
      end

      it "Jobが増えていること" do
        expect{subject}.to change(Job, :count).by(1)
      end
    end

    context "Jobが存在する場合" do
      before do
        Job.create(action: ConsultManagement::Concerns::AddJob::JOB_ACTION)
      end

      it "Jobが増えていないこと" do
        expect{subject}.to change(Job, :count).by(0)
      end
    end
  end
end
