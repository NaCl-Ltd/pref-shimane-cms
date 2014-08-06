require 'spec_helper'

describe Susanoo::Exports::Helpers::ServerSyncHelper do
  class ServerSyncHelperIncluded
    include Susanoo::Exports::Helpers::ServerSyncHelper
  end

  subject{ ServerSyncHelperIncluded.new }

  describe "メソッド" do
    it "ServerSync::Worker のアクションメソッドがが定義されていること" do
      expect(subject.public_methods(false)).to match_array(Susanoo::ServerSync::Worker.action_methods.to_a.map(&:to_sym))
    end

    Susanoo::ServerSync::Worker.action_methods.to_a.each do |action|
      describe "##{action}" do
        let(:arg1) { '/path/to/page' }

        before do
          allow(Settings.export).to receive(:sync_enable_file_path).and_return(__FILE__)
        end

        context "\#{Settings.export.sync_enable_file_path} のファイルが存在する場合" do
          before do
            allow(Settings.export).to receive(:sync_enable_file_path).and_return(__FILE__)
          end

          it "#{action} のジョブが追加されること" do
            expect do
              subject.send(action, arg1)
            end.to change{Job.count}.by(1)

            expect(Job.last.attributes).to include({
              action: action,
              datetime: nil,
              arg1: arg1,
              arg2: nil
            }.stringify_keys)
          end
        end

        context "\#{Settings.export.sync_enable_file_path} のファイルが存在しない場合" do
          before do
            allow(Settings.export).to receive(:sync_enable_file_path).and_return(File.join(__FILE__, 'miss'))
          end

          it "#{action} のジョブが追加されること" do
            expect do
              subject.send(action, arg1)
            end.to change{Job.count}.by(1)

            expect(Job.last.attributes).to include({
              action: action,
              datetime: nil,
              arg1: arg1,
              arg2: nil
            }.stringify_keys)
          end
        end

        it "未来時間が指定されているジョブは削除されること" do
          now = Time.zone.at(Time.zone.now.to_i)
          allow(Time.zone).to receive(:now).and_return(now)

          keep_jobs = []
          dele_jobs = []
          keep_jobs << create(:job, datetime: now - 1.seconds, action: action, arg1: arg1)
          keep_jobs << create(:job, datetime: now + 0.seconds, action: action, arg1: arg1)
          keep_jobs << create(:job, datetime: now + 1.seconds, action: action, arg1: arg1)
          dele_jobs << create(:job, datetime: now + 2.seconds, action: action, arg1: arg1)
          dele_jobs << create(:job, datetime: now + 3.seconds, action: action, arg1: arg1)

          keep_jobs << create(:job, datetime: now + 2.seconds, action: 'non-target', arg1: arg1)
          keep_jobs << create(:job, datetime: now + 2.seconds, action: action, arg1: 'non-target')

          subject.send(action, arg1)

          jobs = keep_jobs + dele_jobs
          expect(Job.where(id: jobs.map(&:id)).to_a).to match_array(keep_jobs)
        end
      end
    end
  end
end

