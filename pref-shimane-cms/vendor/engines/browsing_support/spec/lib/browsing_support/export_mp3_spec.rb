require 'spec_helper'

describe "BrowsingSupport::ExportMp3" do
  subject { BrowsingSupport::ExportMp3.new }

  describe 'メソッド' do
    before do
      BrowsingSupport::VoiceSynthesis.any_instance.stub(:html2m3u)
    end

    describe '.action_methods' do
      it 'create_mp3 があること' do
        expect(BrowsingSupport::ExportMp3.action_methods).to include "create_mp3"
      end
    end

    describe '.run' do
      let(:job1) { create(:job, action: 'create_mp3', arg1: 'a1', arg2: 'a2') }
      let(:job2) { create(:job, action: 'create_mp3', arg1: 'b1', arg2: 'b2') }
      let(:job3) { create(:job, action: 'create_mp3', arg1: 'c1', arg2: 'c2') }

      before do
        allow_any_instance_of(BrowsingSupport::ExportMp3).to receive(:run)
        allow_any_instance_of(BrowsingSupport::ExportMp3).to receive(:logger).and_return(Rails.logger)
      end

      context '排他ロック' do
        let(:tmpdir) { Dir.mktmpdir }
        let(:lock_file) { Pathname.new(tmpdir).join('export_mp3.lock') }

        before do
          allow(BrowsingSupport::ExportMp3).to receive(:lock_file).and_return(lock_file)
        end
        after do
          FileUtils.rm_rf tmpdir
        end

        context '他のプロセスで実行されている場合' do
          around do |example|
            File.open(lock_file, 'w') do |f|
              f.flock(File::LOCK_EX|File::LOCK_NB)
              example.call
            end
          end

          it '実行しないこと' do
            expect{|b| BrowsingSupport::ExportMp3.lock!(&b) }.to_not yield_control

            BrowsingSupport::ExportMp3.run
          end

          it 'ロックファイルは存在すること' do
            BrowsingSupport::ExportMp3.run

            expect(lock_file).to exist
          end
        end

        context 'このプロセスのみの場合' do
          before do
            File.open(lock_file, 'w') do |f|
            end
          end

          it '実行すること' do
            expect{|b| BrowsingSupport::ExportMp3.lock!(&b) }.to yield_control.once

            BrowsingSupport::ExportMp3.run
          end

          it 'ロックファイルは削除されること' do
            BrowsingSupport::ExportMp3.run

            expect(lock_file).to_not exist
          end
        end
      end

      context 'ジョブが1件も登録されていない場合' do
        it '正常に終了すること' do
          expect do
            subject.class.run
          end.to_not raise_error
        end

        it '#run は呼び出されないこと' do
          expect_any_instance_of(BrowsingSupport::ExportMp3).to_not receive(:run)
          subject.class.run
        end
      end

      context '全ジョブの処理が正常に終了する場合' do
        before do
          # create job
          job1; job2; job3
        end

        it '正常に終了すること' do
          expect do
            subject.class.run
          end.to_not raise_error
        end

        it '#run はジョブの件数分は呼び出されること' do
          expect(subject).to receive(:run).ordered.with(job1)
          expect(subject).to receive(:run).ordered.with(job2)
          expect(subject).to receive(:run).ordered.with(job3)

          allow(BrowsingSupport::ExportMp3).to receive(:new).and_return(subject)
          subject.class.run
        end

        it 'ジョブは削除されること' do
          expect do
            subject.class.run
          end.to change(Job, :count).by(-3)

          expect(job1.class.where(id: job1.id)).to_not exist
          expect(job2.class.where(id: job2.id)).to_not exist
          expect(job3.class.where(id: job3.id)).to_not exist
        end
      end

      context 'ジョブの処理中に例外が発生した場合' do
        before do
          allow(subject).to receive(:run).with(job1)
          allow(subject).to receive(:run).with(job2).and_raise
          allow(subject).to receive(:run).with(job3)

          allow(BrowsingSupport::ExportMp3).to receive(:new).and_return(subject)
        end

        it '正常に終了すること' do
          expect do
            subject.class.run
          end.to_not raise_error
        end

        context 'datetime が設定されていないジョブは' do
          it '削除されること' do
            expect do
              subject.class.run
            end.to change(Job, :count).by(-3)

            expect(job1.class.where(id: job1.id)).to_not exist
            expect(job2.class.where(id: job2.id)).to_not exist
            expect(job3.class.where(id: job3.id)).to_not exist
          end
        end

        context 'datetime が設定ているジョブは' do
          before do
            job2.update_attributes(datetime: 1.hour.ago)
          end

          it '新しいジョブとして追加されること' do
            past_30_min = 30.minutes.ago.round

            Timecop.freeze(past_30_min) do
              expect do
                subject.class.run
              end.to change(Job, :count).by(-2)
            end

            expect(job1.class.where(id: job1.id)).to_not exist
            expect(job2.class.where(id: job2.id)).to_not exist
            expect(job3.class.where(id: job3.id)).to_not exist

            next_datetime = (past_30_min + subject.retry_interval).round
            actual_job = job3.class.where(id: job3.id + 1).first
            expect(actual_job).to be
            expect(actual_job.attributes).to include job2.attributes.merge("id" => job3.id + 1, "datetime" => next_datetime)
          end
        end
      end
    end

    describe '.lock!' do
      let(:tmpdir) { Dir.mktmpdir }
      let(:lock_file) { Pathname.new(tmpdir).join('export_mp3.lock') }

      before do
        allow(BrowsingSupport::ExportMp3).to receive(:lock_file).and_return(lock_file)
      end
      after do
        FileUtils.rm_rf tmpdir
      end

      context '他のプロセスで実行されている場合' do
        around do |example|
          File.open(lock_file, 'w') do |f|
            f.flock(File::LOCK_EX|File::LOCK_NB)
            example.call
          end
        end

        it '実行しないこと' do
          expect{|b| BrowsingSupport::ExportMp3.lock!(&b) }.to_not yield_control

          BrowsingSupport::ExportMp3.lock!{}
        end

        it 'ロックファイルは存在すること' do
          BrowsingSupport::ExportMp3.lock!{}

          expect(lock_file).to exist
        end
      end

      context 'このプロセスのみの場合' do
        before do
          File.open(lock_file, 'w') do |f|
          end
        end

        it '実行すること' do
          expect{|b| BrowsingSupport::ExportMp3.lock!(&b) }.to yield_control.once

          BrowsingSupport::ExportMp3.lock!{}
        end

        it 'ロックファイルは削除されること' do
          BrowsingSupport::ExportMp3.lock!{}

          expect(lock_file).to_not exist
        end

        context 'ロック中に例外が発生した場合' do
          it 'ロックファイルは削除されること' do
            BrowsingSupport::ExportMp3.lock! { raise } rescue nil

            expect(lock_file).to_not exist
          end
        end
      end
    end

    describe '#run' do
      let(:job) { create(:job, action: 'test_job', arg1: 'a1', arg2: 'a2') }

      before do
        BrowsingSupport::ExportMp3.any_instance.stub(job.action)
        BrowsingSupport::ExportMp3.any_instance.stub(:logger).and_return(Rails.logger)
      end

      context 'ジョブの処理が正常に終了する場合' do
        before do
          expect_any_instance_of(BrowsingSupport::ExportMp3).to receive(:test_job).with('a1', 'a2')
        end

        it 'job#action のメソッドが呼び出され、処理が正常に終了すること' do
          expect do
            subject.run(job)
          end.to_not raise_error
        end

        it 'ジョブは削除されないこと' do
          expect do
            subject.run(job)
          end.to change(Job, :count).by(0)
        end
      end

      context 'ジョブの処理中に例外が発生する場合' do
        before do
          expect_any_instance_of(BrowsingSupport::ExportMp3).to receive(:test_job).with('a1', 'a2').and_raise(RuntimeError)
        end

        it '例外が発生し、処理が途中で終了すること' do
          expect do
            subject.run(job)
          end.to raise_error(RuntimeError)
        end

        it 'ジョブは削除されないこと' do
          expect do
            subject.run(job) rescue nil
          end.to change(Job, :count).by(0)
        end
      end
    end

    describe '#create_mp3' do
      let(:tmp_id)  { File.basename(tmp_dir) }
      let(:tmp_dir) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }
      after do
        FileUtils.rm_rf(tmp_dir)
      end

      context 'htmlファイルが存在しない場合' do
        it '音声合成は行われないこと' do
          expect_any_instance_of(BrowsingSupport::VoiceSynthesis).to_not receive(:html2m3u)
          subject.create_mp3("/foo/hoge.html" ,tmp_id)
        end

        it '一時ディレクトリは削除されること' do
          expect(Dir.exist?(tmp_dir)).to be_true
          subject.create_mp3("/foo/hoge.html" ,tmp_id)
          expect(Dir.exist?(tmp_dir)).to be_false
        end
      end

      context 'htmlファイルが存在する場合' do
        around do |example|
          html_file_path = File.join(Settings.export.docroot, "/foo/hoge.html")
          FileUtils.mkdir_p( File.dirname(html_file_path) )
          FileUtils.touch(html_file_path)
          example.run
          FileUtils.rm_rf(Settings.export.docroot)
        end

        it '音声合成は行われること' do
          expect_any_instance_of(BrowsingSupport::VoiceSynthesis).to(
            receive(:html2m3u).
            with(File.join(Settings.export.docroot, "/foo/hoge.html"),
                 File.join(Settings.public_uri, "/foo/hoge.html"),
                 {dest_dir: tmp_dir},
                )
          )
          subject.create_mp3("/foo/hoge.html" ,tmp_id)
        end

        it '一時ディレクトリは削除されないこと' do
          expect(Dir.exist?(tmp_dir)).to be_true
          subject.create_mp3("/foo/hoge.html" ,tmp_id)
          expect(Dir.exist?(tmp_dir)).to be_true
        end

        it 'move_mp3 ジョブは作成されること' do
          expect do
            subject.create_mp3("/foo/hoge.html" ,tmp_id)
          end.to change(Job, :count).by(1)
          expect(Job.last.attributes).to include(
            { action: 'move_mp3',
              arg1: "/foo/hoge.html",
              arg2: tmp_id,
            }.stringify_keys)
        end

        context '音声合成中にエラーが発生した場合' do
          before do
            
            expect_any_instance_of(BrowsingSupport::VoiceSynthesis).to(
              receive(:html2m3u).
              with(File.join(Settings.export.docroot, "/foo/hoge.html"),
                   File.join(Settings.public_uri, "/foo/hoge.html") ,
                   {dest_dir: tmp_dir},
                  ).
              and_raise
            )
          end

          it '一時ディレクトリは削除されること' do
            expect(Dir.exist?(tmp_dir)).to be_true
            expect do
              subject.create_mp3("/foo/hoge.html", tmp_id)
            end.to raise_error(RuntimeError)
            expect(Dir.exist?(tmp_dir)).to be_false
          end

          it 'move_mp3 ジョブは作成されないこと' do
            expect do
              expect do
                subject.create_mp3("/foo/hoge.html", tmp_id)
              end.to raise_error(RuntimeError)
            end.to change(Job, :count).by(0)
          end
        end
      end
    end
  end
end
