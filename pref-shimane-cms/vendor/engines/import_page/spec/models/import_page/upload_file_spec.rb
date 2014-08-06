require 'spec_helper'

describe ImportPage::UploadFile do
  subject { described_class.new(section_id) }
  let(:section_id) { 10 }
  let(:store_dir)  { Pathname.new(described_class.store_path(section_id)) }

  describe '拡張' do
  end

  describe "バリデーション" do
    it { should validate_presence_of(:section_id).with_message(:blank) }
    it { should validate_presence_of(:user_id).with_message(:blank) }
    it { should validate_presence_of(:genre_id).with_message(:blank) }
    it { should validate_presence_of(:file).with_message(:blank) }
  end

  describe "メソッド" do
    it { should respond_to(:section_id, :section_id=) }
    it { should respond_to(:user_id,    :user_id=) }
    it { should respond_to(:genre_id,   :genre_id=) }
    it { should respond_to(:file,       :file=) }
    it { should respond_to(:filename,   :filename=) }

    describe '.store_path' do
      it '.pool_path と 引数の section_id とを join したPathname オブジェクトを返すこと' do
        expect(described_class.store_path(0)).to eq Pathname.new(File.join(described_class.pool_path, '0'))
      end
    end

    describe '.find_by_section_id' do
      subject { described_class.find_by_section_id(section_id) }
      let(:section_id) { 0 }

      context 'nil を指定する場合' do
        let(:section_id) { nil }

        it 'nil を返すこと' do
          expect(subject).to be_nil
        end
      end

      context 'pool_path にない section_id を指定する場合' do
        let(:section_id) { 0 }

        before do
          FileUtils.rm_rf store_dir
        end

        it 'nil を返すこと' do
          expect(subject).to be_nil
        end
      end

      context 'pool_path に存在する section_id を指定する場合' do
        let(:section_id) { 0 }

        before do
          FileUtils.mkdir_p store_dir
        end
        after do
          FileUtils.rm_rf store_dir
        end

        context '<pool_path>/<sectin_id>/genre_id ファイルが存在する場合' do
          let(:genre_id_file) { store_dir.join('genre_id') }

          before do
            File.write(genre_id_file, 10)
          end

          it "#{described_class} のインスタンスを返すこと" do
            expect(subject).to be_instance_of(described_class)
          end

          it '#genre_id にファイルの内容が読み込まれること' do
            expect(subject.genre_id).to eq(10)
          end
        end

        context '<pool_path>/<sectin_id>/genre_id ファイルが存在しない場合' do
          let(:genre_id_file) { store_dir.join('genre_id') }

          before do
            FileUtils.rm_f(genre_id_file)
          end

          it "#{described_class} のインスタンスを返すこと" do
            expect(subject).to be_instance_of(described_class)
          end

          it '#genre_id は nil を返すこと' do
            expect(subject.genre_id).to be_nil
          end
        end

        context '<pool_path>/<sectin_id>/user_id ファイルが存在する場合' do
          let(:user_id_file) { store_dir.join('user_id') }

          before do
            File.write(user_id_file, 10)
          end

          it "#{described_class} のインスタンスを返すこと" do
            expect(subject).to be_instance_of(described_class)
          end

          it '#user_id にファイルの内容が読み込まれること' do
            expect(subject.user_id).to eq(10)
          end
        end

        context '<pool_path>/<sectin_id>/user_id ファイルが存在しない場合' do
          let(:user_id_file) { store_dir.join('user_id') }

          before do
            FileUtils.rm_f(user_id_file)
          end

          it "#{described_class} のインスタンスを返すこと" do
            expect(subject).to be_instance_of(described_class)
          end

          it '#user_id は nil を返すこと' do
            expect(subject.user_id).to be_nil
          end
        end

        context '<pool_path>/<sectin_id>/{a.zip,b.zip} ファイルが存在する場合' do
          before do
            File.write(store_dir.join('b.zip'), '')
            File.write(store_dir.join('a.zip'), '')
          end

          it "#{described_class} のインスタンスを返すこと" do
            expect(subject).to be_instance_of(described_class)
          end

          it '#file に最初に見つかったファイルの fd が設定されること' do
            expect(subject.file).to be_instance_of(File)
            expect(subject.file.path).to eq(Dir[store_dir.join('*.zip')].first.to_s)
          end
        end

        context '<pool_path>/<sectin_id>/user_id ファイルが存在しない場合' do
          before do
            FileUtils.rm_f(store_dir.join('b.zip'))
            FileUtils.rm_f(store_dir.join('a.zip'))
          end

          it "#{described_class} のインスタンスを返すこと" do
            expect(subject).to be_instance_of(described_class)
          end

          it '#file は nil を返すこと' do
            expect(subject.file).to be_nil
          end
        end
      end
    end

    describe '#store' do
      let(:file) do
        Tempfile.open('test', Rails.root.join('tmp')).tap do |fp|
          fp.print(filename)
          fp.close
          fp.open
        end
      end
      let(:filename) { 'a.zip' }
      let(:user_id) { 21 }
      let(:genre_id) { 32 }

      before do
        # ウィルスチェック, htmlファイルのチェックを無効にする
        subject.stub(:validates_virus_of_file)
        subject.stub(:validates_html_files_in_file)

        subject.file = file
        subject.filename = filename
        subject.section_id = section_id
        subject.user_id = user_id
        subject.genre_id = genre_id

        FileUtils.rm_rf store_dir
      end
      after do
        file.close!
        FileUtils.rm_rf store_dir
      end

      context 'バリデーションに成功する場合' do
        it 'true を返すこと' do
          expect(subject.store).to be_true
        end

        it '<pool_path>/<sectin_id>/genre_id が作成されること' do
          genre_id_path = store_dir.join('genre_id')
          subject.store
          expect(genre_id_path.exist?).to be_true
          expect(File.read(genre_id_path)).to eq "#{genre_id}"
        end

        it '<pool_path>/<sectin_id>/user_id が作成されること' do
          user_id_path = store_dir.join('user_id')
          subject.store
          expect(user_id_path.exist?).to be_true
          expect(File.read(user_id_path)).to eq "#{user_id}"
        end

        it '<pool_path>/<sectin_id>/<filename> が作成されること' do
          file_path = store_dir.join(filename)
          subject.store
          expect(file_path.exist?).to be_true
          expect(File.read(file_path)).to eq "#{filename}"
        end

        it '<pool_path>/<sectin_id>/erros は作成されないこと' do
          errors_path = store_dir.join('errors')
          subject.store
          expect(errors_path.exist?).to be_false
        end
      end

      context 'バリデーションに失敗する場合' do
        before do
          FileUtils.rm_rf   store_dir
          FileUtils.mkdir_p store_dir

          subject.stub(:valid?).and_return(false)
        end

        it 'false を返すこと' do
          expect(subject.store).to be_false
        end

        it '<pool_path>/<sectin_id>/genre_id が作成されないこと' do
          genre_id_path = store_dir.join('genre_id')
          expect(genre_id_path.exist?).to be_false
        end

        it '<pool_path>/<sectin_id>/user_id が作成されないこと' do
          user_id_path = store_dir.join('user_id')
          expect(user_id_path.exist?).to be_false
        end

        it '<pool_path>/<sectin_id>/<filename> が作成されないこと' do
          file_path = store_dir.join(filename)
          expect(file_path.exist?).to be_false
        end
      end
    end

    describe '#remove' do
      before do
        FileUtils.mkdir_p store_dir
      end

      context 'section_id が nil の場合' do
        it '<pool_path>/<sectin_id>/ ディレクトリは削除されないこと' do
          expect(store_dir.exist?).to be_true
        end

        it '自分自身を返すこと' do
          expect(subject.remove).to eq subject
        end
      end

      context 'section_id が設定されている場合' do
        context '<pool_path> に <section_id> ディレクトリが存在している場合' do
          it '<pool_path>/<sectin_id>/ ディレクトリは削除されること' do
            expect(store_dir.exist?).to be_true
          end

          it '自分自身を返すこと' do
            expect(subject.remove).to eq subject
          end
        end

        context '<pool_path>/ に <section_id> ディレクトリが存在しない場合' do
          before do
            FileUtils.rm_rf store_dir
          end

          it '自分自身を返すこと' do
            expect do
              expect(subject.remove).to eq subject
            end.to_not raise_error
          end
        end
      end
    end

    describe '#stored?' do
      let(:section_id) { 10 }
      let(:filename)   { 'a.zip' }

      after do
        FileUtils.rm_rf store_dir
      end

      context 'sectin_id, filename が設定されている場合' do
        before do
          subject.section_id = section_id
          subject.filename = filename
        end

        context '<pool_path>/<sectin_id>/ ディレクトリが存在する場合' do
          before do
            FileUtils.mkdir_p store_dir
          end

          context '<pool_path>/<sectin_id>/<filename> ファイルが存在する場合' do
            before do
              FileUtils.touch store_dir.join(subject.filename)
            end

            it 'true を返すこと' do
              expect(subject.stored?).to be_true
            end
          end

          context '<pool_path>/<sectin_id>/<filename> ファイルが存在しない場合' do
            before do
              FileUtils.rm_f store_dir.join(subject.filename)
            end

            it 'false を返すこと' do
              expect(subject.stored?).to be_false
            end
          end
        end

        context '<pool_path>/<sectin_id>/ ディレクトリが存在しない場合' do
          before do
            FileUtils.rm_rf store_dir
          end

          it 'false を返すこと' do
            expect(subject.stored?).to be_false
          end
        end
      end

      context 'sectin_id が未設定、filename が設定されている場合' do
        before do
          subject.section_id = nil
          subject.filename = filename

          FileUtils.mkdir_p store_dir
          FileUtils.touch store_dir.join(subject.filename)
        end

        it 'false を返すこと' do
          expect(subject.stored?).to be_false
        end
      end

      context 'sectin_id が設定、filename が未設定の場合' do
        before do
          subject.section_id = section_id
          subject.filename = nil

          FileUtils.mkdir_p store_dir
          FileUtils.touch store_dir.join(filename)
        end

        it 'false を返すこと' do
          expect(subject.stored?).to be_false
        end
      end
    end

    describe 'validates_importable_genre' do
      let!(:genre) { create(:genre) }
      let(:full_error_message) do
        e = subject.errors
        e.full_message(:genre_id, e.generate_message(:genre_id, :unusable, genre: genre.name))
      end

      context 'フォルダが通常のフォルダである場合' do
        before do
          allow(genre).to receive(:normal?).and_return(true)
          subject.genre = genre
        end

        it 'バリデーションエラーは追加されないこと' do
          subject.validates_importable_genre
          expect(subject.errors.full_messages).to_not include full_error_message
        end
      end

      context 'フォルダが通常のフォルダでない場合' do
        before do
          allow(genre).to receive(:normal?).and_return(false)
          subject.genre = genre
        end

        it 'バリデーションエラーは追加されること' do
          subject.validates_importable_genre
          expect(subject.errors.full_messages).to include full_error_message
        end
      end
    end

    describe '#file_validation' do
      before do
        %i(validates_extname_of_filename validates_format_of_filename
           validates_size_of_file validates_virus_of_file
           validates_html_files_in_file
          ).each do |m|
          subject.stub(m)
        end
      end

      context 'validates_extname_of_filename, validates_format_of_filename, validates_size_of_file をスルーした場合' do
        it 'validates_extname_of_filename メソッドは呼び出されること' do
          expect(subject).to receive(:validates_extname_of_filename)
          subject.send(:file_validation)
        end

        it 'validates_format_of_filename メソッドは呼び出されること' do
          expect(subject).to receive(:validates_format_of_filename)
          subject.send(:file_validation)
        end

        it 'validates_size_of_file メソッドは呼び出されること' do
          expect(subject).to receive(:validates_size_of_file)
          subject.send(:file_validation)
        end

        it 'validates_virus_of_file メソッドが呼び出されること' do
          expect(subject).to receive(:validates_virus_of_file)
          subject.send(:file_validation)
        end

        it 'validates_html_files_in_file メソッドは呼び出されること' do
          expect(subject).to receive(:validates_html_files_in_file)
          subject.send(:file_validation)
        end
      end

      context 'validates_extname_of_filename, validates_format_of_filename, validates_size_of_file のいずれかで検証失敗した場合' do
        before do
          expect(subject.errors).to receive(:size).and_return(0, 1)
        end

        it 'validates_extname_of_filename メソッドは呼び出されること' do
          expect(subject).to receive(:validates_extname_of_filename)
          subject.send(:file_validation)
        end

        it 'validates_format_of_filename メソッドは呼び出されること' do
          expect(subject).to receive(:validates_format_of_filename)
          subject.send(:file_validation)
        end

        it 'validates_size_of_file メソッドは呼び出されること' do
          expect(subject).to receive(:validates_size_of_file)
          subject.send(:file_validation)
        end

        it 'validates_virus_of_file メソッドが呼び出されないこと' do
          expect(subject).to_not receive(:validates_virus_of_file)
          subject.send(:file_validation)
        end

        it 'validates_html_files_in_file メソッドは呼び出されないこと' do
          expect(subject).to_not receive(:validates_html_files_in_file)
          subject.send(:file_validation)
        end
      end
    end

    describe '#validates_extname_of_filename' do
      before do
        subject.errors.clear
      end

      context 'filename が設定されている場合' do
        context 'filename が .zip で終わる場合' do
          before do
            subject.filename = 'a.zip'
          end

          it 'errors にメッセージが追加されないこと' do
            subject.send(:validates_extname_of_filename)
            expect(subject.errors[:base]).to have(:no).items
          end
        end

        context 'filename が .html で終わる場合' do
          before do
            subject.filename = 'a.html'
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_extname_of_filename)
            expect(subject.errors[:base]).to have(1).items
          end
        end

        context 'filename に拡張子が無い場合' do
          before do
            subject.filename = 'a'
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_extname_of_filename)
            expect(subject.errors[:base]).to have(1).items
          end
        end
      end

      context 'filename が設定されていない場合' do
        before do
          subject.filename = nil
        end

        it 'errors にメッセージが追加されないこと' do
          subject.send(:validates_extname_of_filename)
          expect(subject.errors[:base]).to have(:no).items
        end
      end
    end

    describe '#validates_format_of_filename' do
      before do
        subject.errors.clear
      end

      context 'filename が設定されている場合' do
        context 'filename が "a-zA-B0-9.\-_.zip" 場合' do
          before do
            subject.filename =
              ('a'..'z').step.to_a.join +
              ('A'..'Z').step.to_a.join +
              (0..9).step.to_a.join +
              '.-_.zip'
          end

          it 'errors にメッセージが追加されないこと' do
            subject.send(:validates_format_of_filename)
            expect(subject.errors[:filename]).to have(:no).items
          end
        end

        context 'filename が "あ.zip" 場合' do
          before do
            subject.filename = 'あ.zip'
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_format_of_filename)
            expect(subject.errors[:filename]).to have(1).items
          end
        end

        context 'filename が "[].zip" 場合' do
          before do
            subject.filename = '[].zip'
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_format_of_filename)
            expect(subject.errors[:filename]).to have(1).items
          end
        end
      end

      context 'filename が設定されていない場合' do
        before do
          subject.filename = nil
        end

        it 'errors にメッセージが追加されないこと' do
          subject.send(:validates_format_of_filename)
          expect(subject.errors[:filename]).to have(:no).items
        end
      end
    end

    describe '#validates_size_of_file' do
      before do
        subject.errors.clear
      end

      context 'file が設定されている場合' do
        around do |example|
          Tempfile.open('test', Rails.root.join('tmp')) do |fp|
            fp.print 'a'
            fp.close
            fp.open
            subject.file = fp
            example.call
            subject.file = nil
          end
        end

        context 'file.size が max_file_size と等しい場合' do
          before do
            subject.max_file_size = subject.file.size
          end

          it 'errors にメッセージが追加されないこと' do
            subject.send(:validates_size_of_file)
            expect(subject.errors[:file]).to have(:no).items
          end
        end

        context 'file.size が max_file_size より小さい場合' do
          before do
            subject.max_file_size = subject.file.size + 1
          end

          it 'errors にメッセージが追加されないこと' do
            subject.send(:validates_size_of_file)
            expect(subject.errors[:file]).to have(:no).items
          end
        end

        context 'file.size が max_file_size より大きい場合' do
          before do
            subject.max_file_size = subject.file.size - 1
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_size_of_file)
            expect(subject.errors[:file]).to have(1).items
          end
        end
      end

      context 'file が設定されていない場合' do
        before do
          subject.file = nil
        end

        it 'errors にメッセージが追加されないこと' do
          subject.send(:validates_size_of_file)
          expect(subject.errors[:file]).to have(:no).items
        end
      end
    end

    describe '#validates_virus_of_file' do
      before do
        subject.errors.clear

        # system メソッドをスタブ化し、ウィルススキャンコマンドの実行を防ぐ
        subject.stub(:system)
      end

      context 'file が設定、Anti Virus コマンドが設定の場合' do
        around do |example|
          subject.stub(:virus_scan_command).and_return(['av', 'arg1', 'arg2'])

          Tempfile.open('test', Rails.root.join('tmp')) do |fp|
            subject.file = fp
            example.call
            subject.file = nil
          end
        end

        context 'ウィルスが検出された(system メソッドの戻り値が true)場合' do
          before do
            subject.stub(:system).and_return(true)
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_virus_of_file)
            expect(subject.errors[:file]).to have(1).items
          end

          it 'ウィルススキャンコマンドは実行されること' do
            expect(subject).to receive(:system) do |*args|
              expect(args).to have(4).items
              expect(args[0..-2]).to eq ['av', 'arg1', 'arg2']
              expect(args.last).to match(/^#{Rails.root.join('tmp/[^/]+?', File.basename(subject.file.path))}$/)
            end
            subject.send(:validates_virus_of_file)
          end
        end

        context 'ウィルスが検出さない(system メソッドの戻り値が false)場合' do
          before do
            subject.stub(:system).and_return(false)
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_virus_of_file)
            expect(subject.errors[:file]).to have(:no).items
          end

          it 'ウィルススキャンコマンドは実行されること' do
            expect(subject).to receive(:system) do |*args|
              expect(args).to have(4).items
              expect(args[0..-2]).to eq ['av', 'arg1', 'arg2']
              expect(args.last).to match(/^#{Rails.root.join('tmp/[^/]+?', File.basename(subject.file.path))}$/)
            end
            subject.send(:validates_virus_of_file)
          end
        end
      end

      context 'file が未設定、Anti Virus コマンドが設定の場合' do
        before do
          subject.stub(:virus_scan_commnad).and_return(['anti_virus'])
          subject.file = nil
        end

        it 'errors にメッセージが追加されないこと' do
          subject.send(:validates_virus_of_file)
          expect(subject.errors[:file]).to have(:no).items
        end

        it 'ウィルススキャンコマンドは実行されないこと' do
          expect(subject).to_not receive(:system)
          subject.send(:validates_virus_of_file)
        end
      end

      context 'file が設定、Anti Virus コマンドが未設定の場合' do
        around do |example|
          subject.stub(:virus_scan_commnad).and_return([])
          Tempfile.open('test', Rails.root.join('tmp')) do |fp|
            subject.file = fp
            example.call
            subject.file = nil
          end
        end

        it 'errors にメッセージが追加されないこと' do
          subject.send(:validates_virus_of_file)
          expect(subject.errors[:file]).to have(:no).items
        end

        it 'ウィルススキャンコマンドは実行されないこと' do
          expect(subject).to_not receive(:system)
          subject.send(:validates_virus_of_file)
        end
      end
    end

    describe '#validates_html_files_in_file' do
      before do
        subject.errors.clear
      end

      context 'file が設定されている場合' do
        around do |example|
          Tempfile.open('test', Rails.root.join('tmp')) do |fp|
            fp.print 'a'
            fp.close
            fp.open
            subject.file = fp
            example.call
            subject.file = nil
          end
        end

        context 'zipファイルの中に html ファイルが存在する場合' do
          before do
            subject.file = File.open(ImportPage::Engine.root.join('spec/files/include_html_files.zip'))
          end

          it 'errors にメッセージが追加されないこと' do
            subject.send(:validates_html_files_in_file)
            expect(subject.errors[:file]).to have(:no).items
          end
        end

        context 'zipファイルの中に html ファイルが存在しない場合' do
          before do
            subject.file = File.open(ImportPage::Engine.root.join('spec/files/not_include_html_files.zip'))
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_html_files_in_file)
            expect(subject.errors[:file]).to have(1).items
          end
        end

        context 'zipファイルが破損している場合' do
          before do
            subject.file = File.open(ImportPage::Engine.root.join('spec/files/broken.zip'))
          end

          it 'errors にメッセージが追加されること' do
            subject.send(:validates_html_files_in_file)
            expect(subject.errors[:file]).to have(1).items
          end
        end
      end

      context 'file が設定されていない場合' do
        before do
          subject.file = nil
        end

        it 'errors にメッセージが追加されないこと' do
          subject.send(:validates_html_files_in_file)
          expect(subject.errors[:file]).to have(:no).items
        end
      end
    end
  end
end
