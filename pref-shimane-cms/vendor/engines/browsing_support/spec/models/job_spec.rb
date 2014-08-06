require 'spec_helper'

describe Job do
  describe "メソッド" do
    describe ".next_mp3" do
      subject{ Job.next_mp3 }

      context "jobsテーブルにcreate_mp3ジョブが存在する場合" do
        let!(:move_mp3_job) { create(:job, action: 'move_mp3', arg1: '1') }
        let!(:create_mp3_job1) { create(:job, action: 'create_mp3', arg1: '1') }
        let!(:create_mp3_job2) { create(:job, action: 'create_mp3', arg1: '2') }

        it "id の若い create_mp3 ジョブが1件取得できること" do
          expect(subject).to eq(create_mp3_job1)
        end
      end

      context "jobsテーブルにcreate_mp3ジョブが存在しない場合" do
        let!(:move_mp3_job) { create(:job, action: 'move_mp3', arg1: '1') }

        it "nil が返ること" do
          expect(subject).to be_nil
        end
      end
    end
  end
end
