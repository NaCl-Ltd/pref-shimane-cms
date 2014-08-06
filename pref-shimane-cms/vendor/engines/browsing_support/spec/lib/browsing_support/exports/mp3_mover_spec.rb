require 'spec_helper'

describe "BrowsingSupport::Exports::Mp3Mover" do
  include Susanoo::Exports::Helpers::PathHelper

  subject { BrowsingSupport::Exports::Mp3Mover.new }

  describe '拡張' do
    it 'BrowsingSupport::Exports::Helpers::PathHelper を include していること' do
      expect(subject.class.included_modules).to include BrowsingSupport::Exports::Helpers::PathHelper
    end
  end

  describe 'メソッド' do
    before do
      subject.logger = Rails.logger
    end

    describe '#move' do
      let(:tmp_id)  { File.basename(tmp_dir) }
      let(:tmp_dir) { Dir.mktmpdir(nil, Rails.root.join('tmp')) }

      before do
        FileUtils.mkdir_p(export_path("foo"))

        # 音声合成で作成されたファイル
        mp3_files = []
        3.times do |n|
          file_basename = "hoge.#{n.next}"
          mp3_files << "#{file_basename}.mp3"
          FileUtils.touch(File.join(tmp_dir, "#{file_basename}.mp3"))
          FileUtils.touch(File.join(tmp_dir, "#{file_basename}.md5"))
        end
        File.write(
          File.join(tmp_dir, 'hoge.m3u'),
          mp3_files.map{|s| File.join('http://localhost/', s) }.join("\n")
        )
        # 以前の音声合成ファイル
        3.times do |n|
          FileUtils.touch(export_path("foo/hoge.1#{n.next}.mp3"))
          FileUtils.touch(export_path("foo/hoge.1#{n.next}.md5"))
        end
      end
      after do
        FileUtils.rm_rf(tmp_dir)
        FileUtils.rm_rf(export_path("foo"))
      end

      context 'tmp_dir ディレクトリが存在しない場合' do
        before do
          FileUtils.rm_rf(tmp_dir)
        end

        it '音声ファイルはコピーされないこと' do
          basename = export_path('foo/hoge')
          expected = %w(mp3 md5).map do |ext|
            (1..3).step(1).to_a.map {|n| "#{basename}.1#{n}.#{ext}" }
          end.flatten

          subject.move("/foo/hoge.html" ,tmp_id)
          expect(Dir["#{basename}.*.mp3", "#{basename}.*.md5"]).
            to match_array(expected)
        end

        it '同期は行われないこと' do
          expect(subject).to_not receive(:sync_docroot)
          subject.move("/foo/hoge.html" ,tmp_id)
        end
      end

      context 'htmlファイルが存在しない場合' do
        it '同期は行われないこと' do
          expect(subject).to_not receive(:sync_docroot)
          subject.move("/foo/hoge.html" ,tmp_id)
        end

        it '音声ファイルはコピーされないこと' do
          basename = export_path('foo/hoge')
          expected = %w(mp3 md5).map do |ext|
            (1..3).step(1).to_a.map {|n| "#{basename}.1#{n}.#{ext}" }
          end.flatten

          subject.move("/foo/hoge.html" ,tmp_id)
          expect(Dir["#{basename}.*.mp3", "#{basename}.*.md5"]).
            to match_array(expected)
        end

        it '一時ディレクトリは削除されること' do
          expect(Dir.exist?(tmp_dir)).to be_true
          subject.move("/foo/hoge.html" ,tmp_id)
          expect(Dir.exist?(tmp_dir)).to be_false
        end
      end

      context 'htmlファイルが存在する場合' do
        around do |example|
          html_file_path = export_path("/foo/hoge.html")
          dirs = FileUtils.mkdir_p(html_file_path.dirname)
          FileUtils.touch(html_file_path)
          example.run
          FileUtils.rm_rf(dirs)
        end

        it '音声ファイルはコピーされ、不要なファイルは削除されること' do
          basename = export_path('foo/hoge')
          expected = %w(mp3 md5).map do |ext|
            (1..3).step(1).to_a.map {|n| "#{basename}.#{n}.#{ext}" }
          end.flatten

          subject.move("/foo/hoge.html" ,tmp_id)
          expect(Dir["#{basename}.*.mp3", "#{basename}.*.md5"]).
            to match_array(expected)
        end

        it '同期は行われること' do
          expect(subject).to receive(:sync_docroot).with('/foo/hoge.*.mp3')
          expect(subject).to receive(:sync_docroot).with('/foo/hoge.m3u')
          subject.move('/foo/hoge.html' ,tmp_id)
        end

        it '一時ディレクトリは削除されること' do
          expect(Dir.exist?(tmp_dir)).to be_true
          subject.move("/foo/hoge.html" ,tmp_id)
          expect(Dir.exist?(tmp_dir)).to be_false
        end

        context '同期中にエラーが発生した場合' do
          before do
            expect(subject).to receive(:sync_docroot).and_raise
          end

          it '一時ディレクトリは削除されること' do
            expect(Dir.exist?(tmp_dir)).to be_true
            subject.move("/foo/hoge.html" ,tmp_id)
            expect(Dir.exist?(tmp_dir)).to be_false
          end
        end
      end
    end
  end
end
