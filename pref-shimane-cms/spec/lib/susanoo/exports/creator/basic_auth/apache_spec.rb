require 'spec_helper'

describe Susanoo::Exports::Creator::BasicAuth::Apache do
  describe "メソッド" do
    before do
      allow_any_instance_of(Susanoo::Exports::Creator::Base).to receive(:rsync)
    end

    describe "#sync_docroot" do
      let(:genre) { create(:genre) }
      let(:apache) { Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id) }

      it "定義されていること" do
        expect(apache).to respond_to(:sync_docroot)
      end
    end

    describe "#sync_docroot" do
      let(:genre) { create(:genre) }
      let(:apache) { Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id) }

      it "定義されていること" do
        expect(apache).to respond_to(:sync_docroot)
      end
    end

    describe "#make" do
      let(:genre) { create(:genre) }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
      end

      it "#make_htaccessを呼び出していること" do
        expect(@apache).to receive(:make_htaccess)
        @apache.make
      end

      it "#make_htpasswdを呼び出していること" do
        expect(@apache).to receive(:make_htpasswd)
        @apache.make
      end
    end

    describe "#delete" do
      let(:genre) { create(:genre) }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
      end

      it "#delete_htaccessを呼び出していること" do
        expect(@apache).to receive(:delete_htaccess)
        @apache.delete
      end

      it "#delete_htpasswdを呼び出していること" do
        expect(@apache).to receive(:delete_htpasswd)
        @apache.delete
      end
    end

    describe "#make_htpasswd" do
      let(:genre) { create(:genre) }
      let!(:web_monitors) { [create(:web_monitor, genre_id: genre.id, state: WebMonitor.status[:registered])] }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
        template = ERB.new(File.read(Susanoo::Exports::Creator::BasicAuth::TEMPLATE_DIR.join('apache', 'htpasswd.erb')), nil, '-')
        @htpasswd_content = template.result(binding)
        @path = @apache.instance_eval{ @htpasswd_path }
      end

      it "htpasswdファイルを作成して書き込んでいること" do
        expect(@apache).to receive(:_write_file).with(@path, @htpasswd_content)
        @apache.make_htpasswd
      end

      it "#sync_htpasswd_fileメソッドを呼び出していること" do
        expect(@apache).to receive(:sync_htpasswd_file)
        @apache.make_htpasswd
      end
    end

    describe "#delete_htpasswd" do
      let(:genre) { create(:genre) }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
        @path = @apache.instance_eval{ @htpasswd_path }
      end

      it "#remove_fileを正しく呼び出していること" do
        expect(@apache).to receive(:_remove_file).with(@path)
        @apache.delete_htpasswd
      end

      it "#sync_htpasswd_fileを正しく呼び出していること" do
        expect(@apache).to receive(:sync_htpasswd_file)
        @apache.delete_htpasswd
      end
    end

    describe "#delete_passwd_with_login" do
      let(:genre) { create(:genre) }
      let!(:web_monitors) { 3.times.map{ create(:web_monitor, genre_id: genre.id, state: WebMonitor.status[:registered]) }}

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
        template = ERB.new(File.read(Susanoo::Exports::Creator::BasicAuth::TEMPLATE_DIR.join('apache', 'htpasswd.erb')), nil, '-')
        @htpasswd_content = template.result(binding)
        @path = @apache.instance_eval{ @htpasswd_path }

        FileUtils.mkdir_p(File.dirname(@path))
        File.open(@path, 'w') {|f| f.print(@htpasswd_content)}
      end

      it "引数で指定したログインを除外して、ファイルに書き直していること" do
        @apache.delete_htpasswd_with_login('test1')

        c = @htpasswd_content.lines.reject{|line| line =~ /^test1:/}.join
        expect(File.read(@path)).to eq  c
      end
    end

    describe "#make_htaccess" do
      before do
        @genre = create(:genre)
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(@genre.id)
        template = ERB.new(File.read(Susanoo::Exports::Creator::BasicAuth::Apache.template_path[:htaccess]), nil, '-')
        @htaccess_content = template.result(binding)
        @path = @apache.instance_eval{ @htaccess_path }
      end

      it "htaccessファイルを作成して書き込んでいること" do
        expect(@apache).to receive(:write_file).with(@path, @htaccess_content)
        @apache.send(:make_htaccess)
      end

      it "#sync_htpaccess_fileメソッドを呼び出していること" do
        expect(@apache).to receive(:sync_htaccess_file)
        @apache.send(:make_htaccess)
      end
    end

    describe "#delete_htaccess" do
      let(:genre) { create(:genre) }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
        @path = @apache.instance_eval{ @htaccess_path }
      end

      it "#remove_fileを正しく呼び出していること" do
        expect(@apache).to receive(:remove_file).with(@path)
        @apache.send(:delete_htaccess)
      end

      it "#sync_htacccess_fileを正しく呼び出していること" do
        expect(@apache).to receive(:sync_htaccess_file)
        @apache.send(:delete_htaccess)
      end
    end

    describe "#sync_htaccess_file" do
      let(:top_genre) { create(:top_genre) }
      let(:genre) { create(:genre, parent_id: top_genre.id) }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
        @path = @apache.instance_eval{ @htaccess_path }
      end

      it "#sync_docrootを正しく呼び出していること" do
        expect(@apache).to receive(:sync_docroot).with(@path)
        @apache.send(:sync_htaccess_file)
      end
    end

    describe "#sync_htpasswd_file" do
      let(:genre) { create(:genre) }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
        @path = @apache.instance_eval{ @htpasswd_path }
      end

      it "#sync_htpasswdを正しく呼び出していること" do
        expect(@apache).to receive(:sync_htpasswd).with(File.basename(@path))
        @apache.send(:sync_htpasswd_file)
      end
    end

    describe "#_write_file" do
      let(:genre) { create(:genre) }
      let(:tmpdir) { Dir.mktmpdir }
      let(:path) { File.join(tmpdir, '/test/index.html') }
      let(:content) { '<p>test</p>' }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)
      end

      after do
        FileUtils.rm_rf tmpdir
      end

      context "ファイルの中身が変更されている場合" do
        before do
          @apache.send(:_write_file, path, content)
        end

        it "Export用のフォルダにファイルを書き込むこと" do
          expect(File.read(path)).to eq(content)
        end
      end

      context "ファイルの中身が変更されていない場合" do
        before do
          FileUtils.mkdir_p File.dirname(path)
          File.open(path, 'w') {|f| f.print(content)}
        end

        it "falseが返ること" do
          expect(@apache.send(:_write_file, path, content)).to be_false
        end
      end
    end

    describe "#_remove_file" do
      let(:genre) { create(:genre) }
      let(:tmpdir) { Dir.mktmpdir }
      let(:src_path) { File.join(tmpdir, '/index.html') }

      before do
        @apache = Susanoo::Exports::Creator::BasicAuth::Apache.new(genre.id)

        FileUtils.mkdir_p File.dirname(src_path)
        File.open(src_path, 'w') {|f| f.print('test')}
        @apache.send(:_remove_file, src_path)
      end

      after do
        FileUtils.rm_rf tmpdir
      end

      it "ファイルが削除されていること" do
        expect(File.exist?(src_path)).to be_false
      end
    end
  end
end

