require 'spec_helper'

describe ImportPage::Importer do
  subject{ described_class.new(section_id) }
  let(:section_id) { 10 }
  let(:store_dir)  { Pathname.new(Settings.import_page.pool_path).join("#{section_id}") }

  around do |example|
    old = described_class.visitor_data_root
    described_class.visitor_data_root = ImportPage::Engine.root.join('files/visitor_data_test')
    example.call
    described_class.visitor_data_root = old
  end
  after do
    FileUtils.rm_rf ImportPage::Engine.root.join('files/visitor_data_test')
  end

  describe "メソッド" do
    after do
      FileUtils.rm_rf(store_dir)
    end

    it { should respond_to(:messages) }
    it { should respond_to(:section_id) }
    it { should respond_to(:user_id) }
    it { should respond_to(:genre) }

    describe '.run' do
      before do
        FileUtils.rm_rf(Dir[File.join(Settings.import_page.pool_path, '**')])
        FileUtils.mkdir_p(File.join(Settings.import_page.pool_path, '1'))
        FileUtils.mkdir_p(File.join(Settings.import_page.pool_path, '2'))
        FileUtils.touch  (File.join(Settings.import_page.pool_path, '3')) # File
        FileUtils.mkdir_p(File.join(Settings.import_page.pool_path, '4'))
        FileUtils.mkdir_p(File.join(Settings.import_page.pool_path, '5.bak')) # invalid
        FileUtils.mkdir_p(File.join(Settings.import_page.pool_path, '6'))
      end

      after do
        FileUtils.rm_rf(Dir[File.join(Settings.import_page.pool_path, '**')])
      end

#      it '1, 2, 4, 6 と処理すること' do
#        expect(described_class).to receive(:initialize).with('1')
#        expect(described_class).to receive(:initialize).with('2')
#        expect(described_class).to receive(:initialize).with('4')
#        expect(described_class).to receive(:initialize).with('6')
#        described_class.run
#      end
    end

    describe '#run' do
      before do
        FileUtils.mkdir_p(store_dir)
      end
      after do
        FileUtils.rm_rf(store_dir)
      end

      context '#import が正常に終了する場合' do
        before do
          FileUtils.touch(store_dir.join('a.zip'))
          allow(subject).to receive(:import)
        end

        it '<store_dir>/error にインポート結果が書き込まれること' do
          allow(subject).to receive(:messages).and_return([{a: 0}, {b: 1}])
          expect(store_dir.join('error').exist?).to be_false
          subject.run
          expect(store_dir.join('error').exist?).to be_true
          expect(store_dir.join('error').read).to eq(
            [ {a: 0}, {b: 1} ].to_json
          )
        end

        it '<store_dir>/*.zip は削除されること' do
          expect(Dir[store_dir.join('*.zip')]).to match_array([store_dir.join('a.zip').to_s])
          subject.run
          expect(Dir[store_dir.join('*.zip')]).to be_empty
        end
      end

      context '#import で例外が発生した場合' do
        before do
          FileUtils.touch(store_dir.join('a.zip'))
          allow(subject).to receive(:import).and_raise
        end

        it '#run 内で処理されること' do
          expect do
            subject.run
          end.to_not raise_error
        end

        it '<store_dir>/error にインポート結果が書き込まれること' do
          allow(subject).to receive(:messages).and_return([{a: 0}, {b: 1}])
          expect(store_dir.join('error').exist?).to be_false
          subject.run rescue nil
          expect(store_dir.join('error').exist?).to be_true
          expect(store_dir.join('error').read).to eq(
            [ {a: 0}, {b: 1} ].to_json
          )
        end

        it '<store_dir>/*.zip は削除されること' do
          expect(Dir[store_dir.join('*.zip')]).to match_array([store_dir.join('a.zip').to_s])
          subject.run rescue nil
          expect(Dir[store_dir.join('*.zip')]).to be_empty
        end
      end
    end

    describe 'import' do
      let(:section_id) { section.id }
      let!(:section) { create(:section) }
      let!(:genre)   { create(:genre).reload }

      before do
        # ページのアクセシビリティのチェックを無効化
        allow_any_instance_of(Susanoo::AccessibilityChecker).to receive(:run)

        FileUtils.mkdir_p(store_dir)
        FileUtils.touch(store_dir.join('a.zip'))
      end

      after do
        FileUtils.rm_rf(store_dir)
      end

      context '取込先のフォルダが削除された場合' do
        before do
          allow(subject).to receive(:genre).and_return(nil)
        end

        it '処理は正常に終了すること' do
          expect do
            subject.import
          end.to_not raise_error
        end

        it 'メッセージが追加されること' do
          subject.import rescue nil
          expect(subject.messages).to match_array([
            I18n.t(:genre_not_found, scope: subject.class.i18n_message_scope),
          ])
        end
      end

      context 'ImportPage::ExtractArchiveError が発生した場合' do
        before do
          allow(subject).to receive(:genre).and_return(genre)
          allow(subject).to receive(:extract!).and_raise(ImportPage::ExtractArchiveError)
        end

        it '処理は正常に終了すること' do
          expect do
            subject.import
          end.to_not raise_error
        end

        it 'メッセージが追加されること' do
          subject.import rescue nil
          expect(subject.messages).to match_array([
            I18n.t(:compressed_file_broken, scope: subject.class.i18n_message_scope),
          ])
        end
      end

      context 'example1 を利用したテスト' do
        # htmlファイルが存在しないフォルダがあるので、取り込みに失敗する

        before do
          FileUtils.rm_rf(store_dir)
          FileUtils.mkdir_p(store_dir)
          FileUtils.cp_r(ImportPage::Engine.root.join('spec/files/examples/import_example1'), store_dir.join('extract'))

          File.write store_dir.join('genre_id'), genre.id
          File.write store_dir.join('a.zip'), ''

          # 展開できたことにする
          subject.stub(:extract_archive).and_return('')
        end

        it 'Genre は登録されないこと' do
          expect do
            subject.import
          end.to change(Genre, :count).by(0)
        end

        it 'Page は登録されないこと' do
          expect do
            subject.import
          end.to change(Page, :count).by(0)
        end

        it 'PageContent は登録されないこと' do
          expect do
            subject.import
          end.to change(PageContent, :count).by(0)
        end

        it 'メッセージは追加されること' do
          subject.import
          expect(subject.messages).to have(1).item
        end

        it '添付ファイルは保存されないこと' do
          subject.import
          expect(Dir[File.join(subject.visitor_data_root, '**/**')]).to be_empty
        end

        it '圧縮ファイルは削除されないこと' do
          subject.import
          expect(Dir[store_dir.join('*.zip')]).to be_any
        end

        it 'result ファイルが作成されないこと' do
          subject.import
          expect(store_dir.join('error').exist?).to be_false
        end
      end

      context 'import_example2 を利用したテスト' do
        # import_example1からHTMLファイルが無いフォルダを削除したので、取り込めるはず...

        before do
          FileUtils.rm_rf(store_dir)
          FileUtils.mkdir_p(store_dir)
          FileUtils.cp_r(ImportPage::Engine.root.join('spec/files/examples/import_example2'), store_dir.join('extract'))

          File.write store_dir.join('genre_id'), genre.id
          File.write store_dir.join('a.zip'), ''

          # 展開できたことにする
          subject.stub(:extract_archive).and_return('')
        end

        it 'top_genre は登録されていること' do
          subject.import
          expect(Genre.where(name: 'top_genre', parent_id: genre.id)).to exist
        end

        it '/<genre.path>/top_page.html は登録されること' do
          subject.import
          page = Page.includes(:genre).where(name: 'top_page', 'genres.path' => File.join('/', genre.path, '/')).first
          expect(page).to be
          expect(page.attributes).to include({
            'name'  => 'top_page',
            'title' => 'Top Page',
          })
        end

        it '添付ファイル「README.txt」は保存されること' do
          subject.import
          page = Page.includes(:genre).where(name: 'top_page', 'genres.path' => File.join('/', genre.path, '/')).first
          path = File.join(subject.visitor_data_root, page.id.to_s, 'README.txt')
          expect(File.exist?(path))
        end

        it '/<genre.path>/top_genre/page.html は登録されること' do
          subject.import
          page = Page.includes(:genre).where(name: 'page', 'genres.path' => File.join('/', genre.path, 'top_genre/')).first
          expect(page).to be
          expect(page.attributes).to include({
            'name'  => 'page',
            'title' => 'Page',
          })
        end

        it '/<genre.path>/top_genre/genre1 ディレクトリは登録されること' do
          subject.import

          path = File.join('/', genre.path, 'top_genre/genre1/')
          expect(Genre.where(path: path)).to exist
        end

        it '/<genre.path>/top_genre/genre1/page1_1.html は登録されること' do
          subject.import
          page = Page.includes(:genre).where(name: 'page1_1', 'genres.path' => File.join('/', genre.path, 'top_genre/genre1/')).first
          expect(page).to be
          expect(page.attributes).to include({
            'name'  => 'page1_1',
            'title' => 'Page 1-1',
          })
        end

        it '/<genre.path>/top_genre/genre1/page1_2.html は登録されること' do
          subject.import
          page = Page.includes(:genre).where(name: 'page1_2', 'genres.path' => File.join('/', genre.path, 'top_genre/genre1/')).first
          expect(page).to be
          expect(page.attributes).to include({
            'name'  => 'page1_2',
            'title' => 'Page 1-2',
          })
        end

        it 'メッセージは追加されないこと' do
          subject.import
          expect(subject.messages).to have(:no).items
        end

        it '圧縮ファイルは削除されないこと' do
          subject.import
          expect(Dir[store_dir.join('*.zip')]).to be_any
        end

        it 'result ファイルが作成されないこと' do
          subject.import
          expect(store_dir.join('error').exist?).to be_false
        end
      end
    end

    describe '#import_directory' do
      let!(:genre) { create(:genre) }

      before do
        FileUtils.mkdir_p(store_dir)

        allow_any_instance_of(ImportPage::Importers::GenreImporter).to receive(:import)
      end
      after do
        FileUtils.rm_rf(store_dir)
      end

      it 'Importers::GenreImporter#import が呼ばれること' do
        expect_any_instance_of(ImportPage::Importers::GenreImporter).to receive(:import)
        subject.send(:import_directory, '/foo/hoge', genre)
      end

      it '戻り値は Importers::GenreImporter#import と同じであること' do
        new_genre = create(:genre)
        allow_any_instance_of(ImportPage::Importers::GenreImporter).to receive(:import).and_return(new_genre)
        expect(
          subject.send(:import_directory, '/foo/hoge', genre)
        ).to eq new_genre
      end

      it '#messages にImporters::GenreImporter のメッセージが格納されること' do
        allow_any_instance_of(ImportPage::Importers::GenreImporter).to receive(:messages).and_return(%w(msg1 msg2))
        subject.send(:import_directory, '/foo/hoge', genre)
        expect(subject.messages).to match_array([
          { title: I18n.t(:result, scope: subject.class.i18n_message_scope(:genre), path: '/foo/hoge/'),
            messages: %w(msg1 msg2),
          },
        ])
      end
    end

    describe '#import_html_file' do
      let!(:genre) { create(:genre) }

      before do
        FileUtils.mkdir_p(store_dir)

        allow_any_instance_of(ImportPage::Importers::PageImporter).to receive(:import)
      end
      after do
        FileUtils.rm_rf(store_dir)
      end

      it 'Importers::PageImporter#import が呼ばれること' do
        expect_any_instance_of(ImportPage::Importers::PageImporter).to receive(:import)
        subject.send(:import_html_file, '/foo/hoge', genre)
      end

      it '戻り値は Importers::PageImporter#import と同じであること' do
        page = create(:page)
        allow_any_instance_of(ImportPage::Importers::PageImporter).to receive(:import).and_return(page)
        expect(
          subject.send(:import_html_file, '/foo/hoge', genre)
        ).to eq page
      end

      it '#messages にImporters::PageImporter のメッセージが格納されること' do
        allow_any_instance_of(ImportPage::Importers::PageImporter).to receive(:messages).and_return(%w(msg1 msg2))
        subject.send(:import_html_file, '/foo/hoge', genre)
        expect(subject.messages).to match_array([
          { title: I18n.t(:result, scope: subject.class.i18n_message_scope(:page), path: '/foo/hoge'),
            messages: %w(msg1 msg2),
          },
        ])
      end

      it 'Importers::PageImporter#visitor_data_root= は呼ばれないこと' do
        # テストでDBの初期化はトランザクションを用いているため、一時的にトランザクションは利用していないとする
        Page.connection.stub(:transaction_open?).and_return(false)
        allow_any_instance_of(ImportPage::Importers::PageImporter).to receive(:import)
        begin
          expect_any_instance_of(ImportPage::Importers::PageImporter).to_not receive(:visitor_data_root=)
          subject.send(:import_html_file, '/foo/hoge', genre)
        ensure
          Page.connection.unstub(:transaction_open?)
        end
      end

      context 'トランザクション内で呼ばれてた場合' do
        around do |example|
          Page.transaction do
            example.call
          end
        end

        it 'Importers::PageImporter#visitor_data_root= は呼ばれること' do
          expect_any_instance_of(ImportPage::Importers::PageImporter).to receive(:visitor_data_root=).with(subject.tmp_visitor_data_root)
          subject.send(:import_html_file, '/foo/hoge', genre)
        end
      end
    end

    describe '#extract!' do
      let(:exdir) { store_dir.join('extract') }
      let(:file_path) { store_dir.join('a.zip') }

      context '正常な zip ファイルが存在する場合' do
        before do
          FileUtils.mkdir_p(File.dirname(file_path))
          FileUtils.cp(
            ImportPage::Engine.root.join('spec/files/examples/correct_zip_example/example.zip'),
            file_path
          )
        end

        context 'ブロック内の処理が正常に終了した場合' do
          it '正常に処理は終了すること' do
            expect do
              subject.send(:extract!) {}
            end.to_not raise_error
          end

          it '解凍先のフォルダは削除されること' do
            FileUtils.mkdir_p(exdir)
            subject.send(:extract!) {} rescue nil
            expect(exdir.exist?).to be_false
          end
        end

        context 'ブロック内で例外が発生した場合' do
          it '例外をそのまま飛ばすこと' do
            expect do
              subject.send(:extract!) { raise }
            end.to raise_error(RuntimeError)
          end

          it '解凍先のフォルダは削除されること' do
            FileUtils.mkdir_p(exdir)
            subject.send(:extract!) { raise } rescue nil
            expect(exdir.exist?).to be_false
          end
        end
      end

      context '破損した zip ファイルが存在する場合' do
        before do
          FileUtils.mkdir_p(File.dirname(file_path))
          FileUtils.cp(
            ImportPage::Engine.root.join('spec/files/examples/broken_zip_example/broken.zip'),
            file_path
          )
        end

        it 'ImportPage::ExtractArchiveError が発生すること' do
          expect do
            subject.send(:extract!) {}
          end.to raise_error(ImportPage::ExtractArchiveError)
        end

        it '解凍先のフォルダは削除されること' do
          FileUtils.mkdir_p(exdir)
          subject.send(:extract!) {} rescue nil
          expect(exdir.exist?).to be_false
        end

        it 'ブロックは呼び出されないこと' do
          block = Proc.new {}
          expect(block).to_not receive(:yield)
          subject.send(:extract!, &block) rescue nil
        end
      end
    end

    describe '#extract_archive' do
      let(:exdir) { store_dir.join('extract') }
      let(:file_path) { store_dir.join('a.zip') }

      before do
        FileUtils.rm_rf(store_dir)
        FileUtils.mkdir_p(store_dir)
      end

      after do
        FileUtils.rm_rf(store_dir)
      end

      context '正常な zip ファイルが存在する場合' do
        before do
          FileUtils.cp(
            ImportPage::Engine.root.join('spec/files/examples/correct_zip_example/example.zip'),
            file_path
          )
          @list = File.readlines(ImportPage::Engine.root.join('spec/files/examples/correct_zip_example/list')).map(&:chop)
        end

        it '戻り値は空文字列であること' do
          expect(
            subject.send(:extract_archive, file_path, exdir)
          ).to eq ''
        end

        it '指定したフォルダに解凍できていること' do
          expect(exdir.exist?).to be_false
          subject.send(:extract_archive, file_path, exdir)
          expect(exdir.exist?).to be_true
          expect(Dir.chdir(exdir){ Dir['**/**'] }).to match_array(@list)
        end
      end

      context '破損した zip ファイルが存在する場合' do
        before do
          FileUtils.cp(
            ImportPage::Engine.root.join('spec/files/examples/broken_zip_example/broken.zip'),
            file_path
          )
        end

        it '戻り値はコマンドのエラーメッセージであること' do
          msg = %x{unzip -qq -o #{file_path} -d #{store_dir.join('hoge')} 2>&1}
          expect(
            subject.send(:extract_archive, file_path, exdir)
          ).to eq msg
        end

        it '解凍用フォルダは存在しないこと' do
          expect(exdir.exist?).to be_false
          subject.send(:extract_archive, file_path, exdir)
          expect(exdir.exist?).to be_false
        end
      end
    end

    describe '#with_transaction' do
      let(:page_id) { 0 }
      before do
        FileUtils.rm_rf subject.tmp_visitor_data_root
        FileUtils.mkdir_p subject.tmp_visitor_data_root.join(page_id.to_s)
        FileUtils.touch subject.tmp_visitor_data_root.join(page_id.to_s, 'a')

        FileUtils.rm_rf File.join(subject.visitor_data_root, page_id.to_s)
      end
      after do
        FileUtils.rm_rf File.join(subject.visitor_data_root, page_id.to_s)
        FileUtils.rm_rf subject.tmp_visitor_data_root
      end

      context 'ブロックの処理が正常に終了した場合' do
        it '一時的保存していた添付ファイルが にコピーされること' do
          path = File.join(subject.visitor_data_root, page_id.to_s, 'a')
          subject.send(:with_transaction) {}
          expect(File.exist?(path)).to be_true
        end

        it '一時的保存の添付ファイルはフォルダごと削除されること' do
          subject.send(:with_transaction) {}
          expect(subject.tmp_visitor_data_root.exist?).to be_false
        end

        it 'DBへの変更は適用されること' do
          page = nil
          expect do
            expect do
              subject.send(:with_transaction) do
                page = create(:page)
                create(:page_content, page: page)
              end
            end.to change(Page, :count).by(1)
          end.to change(PageContent, :count).by(1)
          expect(Page.exists?(page.id)).to be_true
        end
      end

      context 'ブロック内で ActiveRecord::Rollback が発生した場合' do
        it '一時的保存していた添付ファイルが にコピーされないこと' do
          path = File.join(subject.visitor_data_root, page_id.to_s, 'a')
          subject.send(:with_transaction) { raise ActiveRecord::Rollback }
          expect(File.exist?(path)).to be_false
        end

        it '一時的保存の添付ファイルはフォルダごと削除されること' do
          subject.send(:with_transaction) { raise ActiveRecord::Rollback }
          expect(subject.tmp_visitor_data_root.exist?).to be_false
        end

        it 'DBへの変更は適用されないこと' do
          page = nil
          expect do
            expect do
              subject.send(:with_transaction) do
                page = create(:page)
                create(:page_content, page: page)
                raise ActiveRecord::Rollback
              end
            end.to change(Page, :count).by(0)
          end.to change(PageContent, :count).by(0)
          expect(Page.exists?(page.id)).to be_false
        end
      end

      context 'ブロック内で例外が発生した場合' do
        it '例外処理はされないこと' do
          expect do
            subject.send(:with_transaction) { raise }
          end.to raise_error(RuntimeError)
        end

        it '一時的保存していた添付ファイルが にコピーされないこと' do
          path = File.join(subject.visitor_data_root, page_id.to_s, 'a')
          subject.send(:with_transaction) { raise } rescue nil
          expect(File.exists?(path)).to be_false
        end

        it '一時的保存の添付ファイルはフォルダごと削除されること' do
          subject.send(:with_transaction) { raise } rescue nil
          expect(subject.tmp_visitor_data_root.exist?).to be_false
        end

        it 'DBへの変更は適用されないこと' do
          page = nil
          expect do
            expect do
              subject.send(:with_transaction) do
                page = create(:page)
                create(:page_content, page: page)
                raise 
              end rescue nil
            end.to change(Page, :count).by(0)
          end.to change(PageContent, :count).by(0)
          expect(Page.exists?(page.id)).to be_false
        end
      end
    end
  end
end
