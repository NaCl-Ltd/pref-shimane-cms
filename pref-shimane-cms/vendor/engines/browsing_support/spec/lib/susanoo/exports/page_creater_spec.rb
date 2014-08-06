require 'spec_helper'
require 'susanoo/exports/helpers/path_helper'

describe "Susanoo::Exports::PageCreator" do
  include Susanoo::Exports::Helpers::PathHelper

  subject { Susanoo::Exports::PageCreator.new(html_path) }

   around do |example|
     dirs = FileUtils.mkdir_p(export_path(File.dirname(html_path)))
     example.run
     FileUtils.rm_rf(dirs)
   end

  let(:html_path) { '/hoge/foo.html' }
  let(:rubi_path) { path_with_type(html_path, :rubi).to_s }

  describe '拡張' do
    it 'create_normal_page_with_rubi が定義されていること' do
      expect(subject.private_methods).to include :create_normal_page_with_rubi
    end

    it 'create_normal_page_without_rubi が定義されていること' do
      expect(subject.private_methods).to include :create_normal_page_without_rubi
    end

    it 'create_rubi_page が定義されていること' do
      expect(subject.private_methods).to include :create_rubi_page
    end

    it 'prepare_mp3 が定義されていること' do
      expect(subject.private_methods).to include :prepare_mp3
    end
  end

  describe 'メソッド' do
    describe '#create_normal_page' do
      let(:return_value_create_normal_page) { false }

      context 'create_normal_page_without_rubi メソッドの戻り値が false の場合' do
        before do
          allow(subject).to receive(:create_normal_page_without_rubi).and_return(false)
        end

        context 'create_rubi_page メソッドの戻り値が false の場合' do
          before do
            Job.delete_all
            allow(subject).to receive(:create_rubi_page).with(false).and_return(false)
          end

          it '#prepare_mp3 は呼ばれないこと' do
            expect(subject).to_not receive(:prepare_mp3)
            subject.send(:create_normal_page)
          end

          it '戻り値は false であること' do
            expect(subject.send(:create_normal_page)).to be_false
          end
        end

        context 'create_rubi_page メソッドの戻り値が true の場合' do
          before do
            Job.delete_all
            allow(subject).to receive(:create_rubi_page).with(false).and_return(true)
          end

          it '#prepare_mp3 は呼ばれること' do
            expect(subject).to receive(:prepare_mp3).once
            subject.send(:create_normal_page)
          end

          it '戻り値は true であること' do
            expect(subject.send(:create_normal_page)).to be_true
          end
        end
      end

      context 'create_normal_page_without_rubi メソッドの戻り値が true の場合' do
        before do
          allow(subject).to receive(:create_normal_page_without_rubi).and_return(true)
        end

        context 'create_rubi_page メソッドの戻り値が false の場合' do
          before do
            Job.delete_all
            expect(subject).to receive(:create_rubi_page).with(true).and_return(false)
          end

          it '#prepare_mp3 は呼ばれないこと' do
            expect(subject).to_not receive(:prepare_mp3)
            subject.send(:create_normal_page)
          end

          it '戻り値は true であること' do
            expect(subject.send(:create_normal_page)).to be_true
          end
        end

        context 'create_rubi_page メソッドの戻り値が true の場合' do
          before do
            Job.delete_all
            expect(subject).to receive(:create_rubi_page).with(true).and_return(true)
          end

          it '#prepare_mp3 は呼ばれること' do
            expect(subject).to receive(:prepare_mp3).once
            subject.send(:create_normal_page)
          end

          it '戻り値は true であること' do
            expect(subject.send(:create_normal_page)).to be_true
          end
        end
      end
    end

    describe '#create_rubi_page' do
      let(:html) do
        <<__HTML__
<html>
<head><title>MeCabでの態素解析</title></head>
<body>
MeCabで形態素解析を行うとこうなる。
<div>太郎はこの本を二郎を見た女性に渡した。</div>
</body>
</html>
__HTML__
      end
      let(:rubi_html) { BrowsingSupport::RubiAdder.add(html) }

      before do
        write_file(html_path, html)
      end
      after(:all) do
        FileUtils.rm_rf(export_path('/hoge'))
      end

      after do
        FileUtils.rm_f(export_path(rubi_path))
      end

      context 'false を渡す場合' do
        context 'ルビふりページのファイルが存在する場合' do
          context 'ルビふりページの最終更新日時が words テーブルの最終更新日時より進んいる場合' do
            before do
              create(:word, updated_at: Time.now - 1800)
              touch_file(rubi_path)
            end

            it 'ルビふりページは作成されないこと' do
              subject.send(:create_rubi_page, false)

              expect(read_file(rubi_path)).to eq ""
            end

            it '戻り値は false であること' do
              expect(subject.send(:create_rubi_page, false)).to be_false
            end
          end

          context 'ルビふりページの最終更新日時が words テーブルの最終更新日時以下の場合' do
            before do
              create(:word)
              touch_file(rubi_path, mtime: Time.now - 60)
            end

            it 'ルビふりページは作成されること' do
              subject.send(:create_rubi_page, false)

              expect(read_file(rubi_path)).to eq(rubi_html)
            end

            it '戻り値は true であること' do
              expect(subject.send(:create_rubi_page, false)).to be_true
            end
          end
        end

        context 'ルビふりページのファイルが存在しない場合' do
          before do
            FileUtils.rm_rf(export_path(rubi_path))
          end

          it 'ルビふりページは作成されること' do
            subject.send(:create_rubi_page, false)

            expect(read_file(rubi_path)).to eq(rubi_html)
          end

          it '戻り値は true であること' do
            expect(subject.send(:create_rubi_page, false)).to be_true
          end
        end
      end

      context 'true を渡す場合' do
        context 'ルビふりページのファイルが存在する場合' do
          before do
            write_file(rubi_path, "")
          end

          it 'ルビふりページは更新されること' do
            subject.send(:create_rubi_page, true)

            expect(read_file(rubi_path)).to eq(rubi_html)
          end
        end

        context 'ルビふりページのファイルが存在しない場合' do
          before do
            FileUtils.rm_rf(export_path(rubi_path))
          end

          it 'ルビふりページは作成されること' do
            subject.send(:create_rubi_page, true)

            expect(read_file(rubi_path)).to eq(rubi_html)
          end

          it '戻り値は true であること' do
            expect(subject.send(:create_rubi_page, true)).to be_true
          end
        end
      end

      context 'ルビを振る元のhtmlファイルが存在しない場合' do
        before do
          allow(subject).to receive(:read_file).and_return(nil)
        end

        it 'false を返すこと' do
          expect(subject.send(:create_rubi_page, true)).to be_false
        end

        it 'ルビ振りを行わないこと' do
          expect(BrowsingSupport::RubiAdder).to_not receive(:add)
          subject.send(:create_rubi_page, true)
        end
      end

      context 'MeCab の初期化に失敗した場合' do
        before do
          allow(BrowsingSupport::RubiAdder).to receive(:add).and_return(nil)
        end

        let!(:root)  { build(:genre, name: '', path: '/') {|r| r.save!(validate: false) } }
        let!(:genre) { create(:genre, name: 'hoge', parent_id: root.id) }
        let(:html_path) { '/hoge/index.html' }

        context '処理しているページにPageレコードがある場合' do
          let!(:page) { create(:page_publish, name: 'index', genre: genre) }

          it '再実行用ジョブが登録されること' do
            expect {
              subject.send(:create_rubi_page, true)
            }.to change{
              Job.where(action: 'create_page', arg1: page.id.to_s).count
            }.from(0).to(1)
          end

          it '戻り値は false であること' do
            expect(subject.send(:create_rubi_page, true)).to be_false
          end
        end

        context 'Pageレコードがないページ(ジャンルのindex.htmlページ等)の場合' do
          it '再実行用ジョブが登録されること' do
            expect {
              subject.send(:create_rubi_page, true)
            }.to change{
              Job.where(action: 'create_genre', arg1: genre.id.to_s).count
            }.from(0).to(1)
          end

          it '戻り値は false であること' do
            expect(subject.send(:create_rubi_page, true)).to be_false
          end
        end
      end
    end

    describe "#prepare_mp3" do
      let(:m3u_path)  { path_with_type(html_path, :m3u).to_s }

      context "対象の m3u ファイルの修正時刻が html.r ファイルの修正時刻より小さい場合" do
        before do |example|
          last_modefied_at = Time.now
          touch_file(rubi_path, mtime: last_modefied_at)
          touch_file(m3u_path, mtime: last_modefied_at - 10)
        end

        context "create_mp3 ジョブが登録されていない場合" do
          before do
            Job.delete_all(action: :create_mp3, arg1: html_path)
          end

          it "create_mp3 ジョブが作成されること" do
            expect do
              subject.send(:prepare_mp3)
            end.to change(Job, :count).by(1)

            expect(Job.last.attributes).to include({
              'action' => 'create_mp3',
              'arg1'   => html_path,
              'arg2'   => '',
            })
          end
        end

        context "create_mp3 ジョブが登録されている場合" do
          before do
            Job.create(action: :create_mp3, arg1: html_path, arg2: '', datetime: 1.minute.ago)
          end

          it "create_mp3 ジョブが作成されないこと" do
            expect do
              subject.send(:prepare_mp3)
            end.to change(Job, :count).by(0)
          end
        end

        it "m3u ファイルは修正されること" do
          subject.send(:prepare_mp3)

          expect(read_file(m3u_path)).to eq( File.join(Settings.public_uri, 'not_found.mp3') + "\n" )
        end
      end

      context "対象の m3u ファイルの修正時刻と html.r ファイルの修正時刻が等しい場合" do
        before do |example|
          last_modefied_at = Time.now
          touch_file(rubi_path, mtime: last_modefied_at)
          touch_file(m3u_path, mtime: last_modefied_at)
        end

        it "create_mp3 ジョブが作成されること" do
          expect do
            subject.send(:prepare_mp3)
          end.to change(Job, :count).by(1)

          expect(Job.last.attributes).to include({
            'action' => 'create_mp3',
            'arg1'   => html_path,
            'arg2'   => '',
          })
        end

        it "m3u ファイルは修正されること" do
          subject.send(:prepare_mp3)

          expect(read_file(m3u_path)).to eq( File.join(Settings.public_uri, 'not_found.mp3') + "\n" )
        end
      end

      context "対象の m3u ファイルの修正時刻が html.r ファイルの修正時刻より大きい場合" do
        before do |example|
          last_modefied_at = Time.now
          touch_file(rubi_path, mtime: last_modefied_at - 10)
          touch_file(m3u_path, mtime: last_modefied_at)
        end

        it "create_mp3 ジョブが作成されないこと" do
          expect do
            subject.send(:prepare_mp3)
          end.to change(Job, :count).by(0)
        end

        it "m3u ファイルは修正されていないこと" do
          subject.send(:prepare_mp3)

          expect(read_file(m3u_path)).to eq("")
        end
      end

      context "docroot に対象の m3u ファイルが存在しない場合" do
        before do
          last_modefied_at = Time.now
          touch_file(rubi_path, mtime: last_modefied_at)
          remove_file(m3u_path)
        end

        it "create_mp3 ジョブが作成されること" do
          expect do
            subject.send(:prepare_mp3)
          end.to change(Job, :count).by(1)

          expect(Job.last.attributes).to include({
            'action' => 'create_mp3',
            'arg1'   => html_path,
            'arg2'   => '',
          })
        end

        it "m3u ファイルは修正されること" do
          subject.send(:prepare_mp3)

          expect(read_file(m3u_path)).to eq( File.join(Settings.public_uri, 'not_found.mp3') + "\n" )
        end
      end

      context "docroot に対象の rubi ファイルが存在しない場合" do
        before do
          last_modefied_at = Time.now
          remove_file(rubi_path)
          touch_file(m3u_path, mtime: last_modefied_at)
        end

        it "create_mp3 ジョブが作成されないこと" do
          expect do
            subject.send(:prepare_mp3)
          end.to change(Job, :count).by(0)
        end

        it "m3u ファイルは修正されていないこと" do
          subject.send(:prepare_mp3)

          expect(read_file(m3u_path)).to eq("")
        end
      end
    end

    describe "#retry_with_rubi" do
      context "ページの場合" do
        let!(:page) { create(:page_publish) }
        let(:html_path) { page.path }

        context "10分以内に同じページのジョブが存在しない場合" do
          let!(:job) { create(:job, action: 'create_page', arg1: page.id.to_s, datetime: 11.minutes.since) }

          around do |example|
            Timecop.freeze do
              example.call
            end
          end

          it "現時刻から10分後に動作する create_page ジョブが登録されること" do
            expect do
              subject.send(:retry_with_rubi)
            end.to change{ Job.count }.by(1)

            cmp_attrs = %w[action arg1 arg2]
            last_job = Job.last.reload
            expect(last_job.attributes.slice(*cmp_attrs)).to include job.attributes.slice(*cmp_attrs)
            expect(last_job.datetime.to_i).to eq 10.minutes.since.to_i
              # タイムスタンプの精度問題で失敗する時があるため、起算からの経過秒数で比較する
          end

          it "戻り値は登録したジョブのインスタンスであること" do
            v = subject.send(:retry_with_rubi)
            expect(v).to be_an_instance_of Job
            expect(v.id).to eq Job.last.id
          end
        end

        context "10分以内に同じページのジョブが存在する場合" do
          let!(:job) { create(:job, action: 'create_page', arg1: page.id.to_s, datetime: 10.minutes.since) }

          it "create_page ジョブは登録されないこと" do
            expect do
              subject.send(:retry_with_rubi)
            end.to change{ Job.count }.by(0)
          end

          it "戻り値は nil であること" do
            expect(subject.send(:retry_with_rubi)).to be_nil
          end
        end
      end

      context "ジャンルの場合" do
        let!(:genre) { create(:genre).reload }
        let(:html_path) { File.join(genre.path, 'index.html') }

        context "10分以内に同じページのジョブが存在しない場合" do
          let!(:job) { create(:job, action: 'create_genre', arg1: genre.id.to_s, datetime: 11.minutes.since) }

          around do |example|
            Timecop.freeze do
              example.call
            end
          end

          it "現時刻から10分後に動作する create_genre ジョブが登録されること" do
            expect do
              subject.send(:retry_with_rubi)
            end.to change{ Job.count }.by(1)

            cmp_attrs = %w[action arg1 arg2]
            last_job = Job.last
            expect(last_job.attributes.slice(*cmp_attrs)).to include job.attributes.slice(*cmp_attrs)
            expect(last_job.datetime.to_i).to eq 10.minutes.since.to_i
              # タイムスタンプの精度問題で失敗する時があるため、起算からの経過秒数で比較する
          end

          it "戻り値は登録したジョブのインスタンスであること" do
            v = subject.send(:retry_with_rubi)
            expect(v).to be_an_instance_of Job
            expect(v.id).to eq Job.last.id
          end
        end

        context "10分以内に同じページのジョブが存在する場合" do
          let!(:job) { create(:job, action: 'create_genre', arg1: genre.id.to_s, datetime: 10.minutes.since) }

          it "create_genre ジョブは登録されないこと" do
            expect do
              subject.send(:retry_with_rubi)
            end.to change{ Job.count }.by(0)
          end

          it "戻り値は nil であること" do
            expect(subject.send(:retry_with_rubi)).to be_nil
          end
        end
      end
    end
  end

  def write_file(path, body, mode='w')
    path = export_path(path)
    FileUtils.mkdir_p(path.dirname) unless FileTest.exist?(path.dirname)
    File.open(path, mode) {|f| f.print(body)}
    body
  end

  def read_file(path)
    path = export_path(path)
    File.readable?(path) ? File.read(path) : nil
  end

  def touch_file(path, options = {})
    path = export_path(path)
    FileUtils.mkdir_p(path.dirname) unless FileTest.exist?(path.dirname)
    FileUtils.touch(path, options)
  end

  def remove_file(path, options = {})
    path = export_path(path)
    FileUtils.rm(path, {force: true}.update(options))
  end
end
