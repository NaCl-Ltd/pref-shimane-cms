require 'spec_helper'

describe Susanoo::ServerSync::Worker do
  describe "メソッド" do
    subject { Susanoo::ServerSync::Worker.new }

    let(:retry_interval) { Susanoo::ServerSync::Worker.retry_interval }

    before do
      allow(Settings.export).to receive(:sync_enable_file_path).and_return(__FILE__)
    end

    describe "#run" do
      before do
        Susanoo::ServerSync::Worker.action_methods.each do |action|
          allow(subject).to receive(action).and_return(true)
        end
      end

      describe "Job とアクションメソッドとの関係" do
        it "Job#action と対応したアクションメソッドが呼び出されること" do
          Susanoo::ServerSync::Worker.action_methods.each do |action|
            expect(subject).to receive(action)
              .with(create_list(:job, 2, action: action, datetime: nil))
          end
          %i(create_page).each do |action|
            create(:job, action: action, datetime: nil)
            expect(subject).to_not receive(action)
          end

          subject.run
        end

        it "Job が無い場合、アクションメソッドを呼ばず正常終了すること" do
          Job.delete_all

          Susanoo::ServerSync::Worker.action_methods.each do |action|
            expect(subject).to_not receive(action)
          end

          subject.run
        end

        it "100件毎にジョブを消化すること" do
          Job.delete_all

          action = Susanoo::ServerSync::Worker.action_methods.to_a.first
          jobs = create_list(:job, 201, action: action, datetime: nil)

          expect(subject).to receive(action).ordered.with(jobs[  0.. 99])
          expect(subject).to receive(action).ordered.with(jobs[100..199])
          expect(subject).to receive(action).ordered.with(jobs[200..200])

          subject.run
        end
      end

      context "実行対象のジョブに対して" do
        let!(:tz_now) { Time.zone.at(Time.zone.now.to_i) }
        let!(:run_jobs) do
          _jobs = []
          Susanoo::ServerSync::Worker.action_methods.each do |action|
            _jobs << create(:job, action: action, datetime: nil)
            _jobs << create(:job, action: action, datetime: tz_now)
          end
          _jobs.map(&:reload)
        end
        let!(:not_run_jobs) do
          _jobs = []
          Susanoo::ServerSync::Worker.action_methods.each do |action|
            _jobs << create(:job, action: action, datetime: tz_now + 1.second)
          end
          %i(create_page).each do |action|
            _jobs << create(:job, action: action, datetime: nil)
            _jobs << create(:job, action: action, datetime: tz_now)
          end
          _jobs.map(&:reload)
        end

        it "実行対象の Job の datetime は現時刻に更新されること" do
          allow(Job).to receive(:delete_all)  # 削除の無効化
          allow(Time.zone).to receive(:now).and_return(tz_now)
          allow(subject).to receive(:find_jobs_in_batches).and_yield(run_jobs + not_run_jobs)

          subject.run

          run_jobs.each do |job|
            expect_job = job.clone
            expect_job.datetime = tz_now
            expect(job.reload).to eq(expect_job)
          end

          not_run_jobs.each do |job|
            expect_job = job.clone
            expect(job.reload).to eq(expect_job)
          end
        end

        it "Job#action と対応したメソッドが正常終了した場合、実行対象のジョブは削除されること" do
          subject.run

          jobs = run_jobs + not_run_jobs
          expect(Job.where(id: jobs.map(&:id)).to_a).to match_array not_run_jobs
        end

        context "Job#action と対応したメソッドで例外が発生した場合" do
          before do
            Susanoo::ServerSync::Worker.action_methods.each do |action|
              allow(subject).to receive(action).and_raise
            end
            allow(subject).to receive(:retry_interval).and_return(retry_interval)
          end

          let(:retry_interval) { 10.minutes }

          it "実行対象のジョブは削除されないこと" do
            expect do
              subject.run
            end.to change{ Job.count }.by(0)

            expect(Job.where(id: run_jobs.map(&:id)).to_a).to match_array(run_jobs)
          end

          it "実行対象のジョブの datetime は .retry_interval 分増加していること" do
            allow(Time.zone).to receive(:now).and_return(tz_now)

            expected = run_jobs.each{|j| j.assign_attributes(datetime: tz_now + retry_interval) }.map(&:attributes)
            subject.run
            actual = run_jobs.map{|j| j.reload.attributes }

            expect(actual).to match_array(expected)
          end
        end

        context "\#{Settings.export.sync_enable_file_path} ファイルが存在しない場合" do
          it "メソッドを呼び出すことなく処理を終了すること" do
            allow(Settings.export).to receive(:sync_enable_file_path).and_return(File.join(__FILE__, 'miss'))

            Susanoo::ServerSync::Worker.action_methods.each do |action|
              expect(subject).to_not receive(action)
            end

            subject.run
          end
        end
      end
    end

    shared_examples "Susanoo::ServerSync::Worker#sync_docroot" do |run_method|
      def set_sync_servers(servers)
        allow(Settings.export).to receive(:servers).and_return(Array(servers))
      end

      before do
        available_syncers.each do |syncer|
          allow_any_instance_of(syncer).to receive(:run).and_return(true)
        end
      end

      it "Settings.export.servers に登録されているサーバ分の syncer のインスタンスを生成し、run メソッドを呼び出すこと" do
        set_sync_servers(%w(s1 s2 s3))

        new_received_cnt = 0
        run_received_cnt = 0
        allow(use_syncer).to receive(:new) do |*args|
          new_received_cnt += 1
          double(server: args[0], priority: 20).as_null_object.tap do |o|
            expect(o).to receive(:run) { run_received_cnt += 1; nil }.once
          end
        end

        subject.send(run_method, [])

        expect(new_received_cnt).to eq 3
        expect(run_received_cnt).to eq 3
      end

      it "Syncer#sync_files に Job#arg1 の値が追加されること" do
        set_sync_servers(%w(s1 s2))

        syncers = {}
        allow(use_syncer).to receive(:new) do |*args|
          syncers[args[0]] = double(server: args[0], sync_files: [], priority: 20).as_null_object
        end

        jobs = []
        jobs << create(:job, arg1: '/all_servers/page01')
        jobs << create(:job, arg1: '/all_servers/page02')
        subject.send(run_method, jobs)

        expect(syncers.keys).to match_array(['s1', 's2'])
        expect(syncers['s1'].sync_files).to match_array(['/all_servers/page01', '/all_servers/page02'])
        expect(syncers['s2'].sync_files).to match_array(['/all_servers/page01', '/all_servers/page02'])
      end

      it "Job#arg2 にサーバが指定されていた場合、当該サーバに対応した syncer の sync_files に Job#arg1 の値が追加されること" do
        set_sync_servers(%w(s1 s2))

        syncers = {}
        allow(use_syncer).to receive(:new) do |*args|
          syncers[args[0]] = double(server: args[0], sync_files: [], priority: 20).as_null_object
        end

        jobs = []
        jobs << create(:job, arg1: '/all_servers/page01')
        jobs << create(:job, arg1: '/all_servers/page02', arg2: 's1')
        subject.send(run_method, jobs)

        expect(syncers.keys).to match_array(['s1', 's2'])
        expect(syncers['s1'].sync_files).to match_array(['/all_servers/page01', '/all_servers/page02'])
        expect(syncers['s2'].sync_files).to match_array(['/all_servers/page01'])
      end

      context "同期に失敗した場合" do
        before do
          set_sync_servers(%w(s1))
          allow_any_instance_of(use_syncer).to receive(:run).and_return(false)
        end

        let!(:jobs) do
          [ create(:job, action: run_method, arg1: 'p01'),
            create(:job, action: run_method, arg1: 'p02'),
            create(:job, action: run_method, arg1: 'p03'),
          ].map(&:reload)
        end

        it "処理したジョブに対して {datetime: Time.zone.now + retry_interval, arg2: syncer.server} で上書きされたジョブが追加されること" do
          tz_now = Time.zone.at(Time.zone.now.to_i)
          allow(Time.zone).to receive(:now).and_return(tz_now)

          max_job_id = Job.maximum(:id)
          expect do
            subject.send(run_method, jobs)
          end.to change{ Job.count }.by(jobs.size)

          new_jobs = Job.where( Job.arel_table[:id].gt(max_job_id) )
          new_jobs_attrs = new_jobs.map{|j| j.attributes.except('id', 'queue') }
          expect(new_jobs_attrs).to match_array([
            {'datetime' => tz_now + retry_interval, 'action' => "#{run_method}", 'arg1' => 'p01', 'arg2' => 's1'},
            {'datetime' => tz_now + retry_interval, 'action' => "#{run_method}", 'arg1' => 'p02', 'arg2' => 's1'},
            {'datetime' => tz_now + retry_interval, 'action' => "#{run_method}", 'arg1' => 'p03', 'arg2' => 's1'},
          ])
        end

        it "元のジョブは削除、更新されないこと" do
          before_attributes = jobs.map{|j| j.reload.attributes.dup }
          subject.send(run_method, jobs)

          expect(Job.where(id: jobs.map(&:id)).size).to eq jobs.size

          after_attributes = jobs.map{|j| j.reload.attributes.dup }
          expect(after_attributes).to match_array before_attributes
        end
      end
    end

    describe "#sync_docroot" do
      let(:available_syncers) { Susanoo::ServerSync::Syncers::Base.subclasses }
      let(:use_syncer) { Susanoo::ServerSync::Syncers::DocrootSyncer }

      it_behaves_like "Susanoo::ServerSync::Worker#sync_docroot", :sync_docroot
    end

    describe "#sync_counter" do
      let(:available_syncers) { Susanoo::ServerSync::Syncers::Base.subclasses }
      let(:use_syncer) { Susanoo::ServerSync::Syncers::CounterSyncer }

      it_behaves_like "Susanoo::ServerSync::Worker#sync_docroot", :sync_counter do
        def set_sync_servers(servers)
          allow(Settings.export).to receive(:sync_counter_servers).and_return(Array(servers))
        end
      end
    end

    describe "#sync_htpasswd" do
      let(:available_syncers) { Susanoo::ServerSync::Syncers::Base.subclasses }
      let(:use_syncer) { Susanoo::ServerSync::Syncers::HtpasswdSyncer }

      it_behaves_like "Susanoo::ServerSync::Worker#sync_docroot", :sync_htpasswd
    end
  end
end
