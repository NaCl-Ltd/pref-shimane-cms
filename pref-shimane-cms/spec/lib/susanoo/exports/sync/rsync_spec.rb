require 'spec_helper'

describe Susanoo::Exports::Sync::Rsync do
  include Susanoo::Exports::Sync::Rsync

  describe "メソッド" do
    let(:do_sync_path) { Susanoo::Exports::Sync::Rsync::SYNC_ENABLE_FILE_PATH }
    before do
      File.open(do_sync_path, 'w') do |f|
        f.print 'do_sync_file'
      end
    end

    describe "#rsync" do
      let(:src) { '/genre1' }
      let(:dest) { '/genre2' }

      it "#run_commandメソッドを実行していること" do
        options = Susanoo::Exports::Sync::Rsync::DEFAULT_OPTIONS
        user = Susanoo::Exports::Sync::Rsync::USER
        Settings.export.servers.each do |server|
          expect_any_instance_of(Susanoo::Exports::Sync::Rsync).to receive(:run_command).with(
            "rsync #{options} #{Settings.export.docroot + src} #{user}@#{server}:#{Settings.export.sync_dest_dir + dest}"
          )
        end
        rsync(src, dest)
      end
    end

    describe "#create_src_path" do
      let(:file_name) { '/test1.txt' }

      context "dirが指定されている場合" do
        let(:dir) { '/test1/' }

        it "dirとファイル名を連結したパスを返すこと" do
          expect(create_src_path(dir, file_name)).to eq(dir + file_name)
        end
      end

      context "dirがnilの場合" do
        it "dirを設定ファイルから取得していること" do
          expect(create_src_path(nil, file_name)).to eq(Settings.export.docroot + file_name)
        end
      end
    end

    describe "#create_dest_path" do
      let(:file_name) { '/test1.txt' }

      context "dirが指定されている場合" do
        let(:dir) { '/test1/' }

        it "dirとファイル名を連結したパスを返すこと" do
          expect(create_dest_path(dir, file_name)).to eq(dir + file_name)
        end
      end

      context "dirがnilの場合" do
        it "dirを設定ファイルから取得していること" do
          expect(create_dest_path(nil, file_name)).to eq(Settings.export.sync_dest_dir + file_name)
        end
      end
    end

    after do
      do_sync_path = Susanoo::Exports::Sync::Rsync::SYNC_ENABLE_FILE_PATH
      File.delete(do_sync_path)
    end
  end
end

