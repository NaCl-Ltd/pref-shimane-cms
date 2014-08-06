require 'spec_helper'

describe ImportPage::Importers::GenreImporter do
  subject{ described_class.new(section.id, genre, user.id, import_path) }
  let!(:section) { create(:section) }
  let!(:genre) { create(:genre) }
  let!(:user) { create(:user) }

  let(:store_dir)  { Pathname.new(ImportPage::UploadFile.store_path(section.id)) }
  let(:import_path) { store_dir.join(import_dirname) }
  let(:import_dirname) { 'import_genre' }

  after do
    FileUtils.rm_rf(store_dir)
  end

  describe "メソッド" do
    it { should respond_to(:messages) }
    it { should respond_to(:section_id) }
    it { should respond_to(:genre) }
    it { should respond_to(:user_id) }
    it { should respond_to(:path) }

    describe 'import' do
      before do
        FileUtils.mkdir_p(import_path)
      end

      after do
        FileUtils.rm_rf(import_path)
      end

      context 'インポートするディレクトリ直下に1つでもHTMLファイル(.html)が存在する場合' do
        before do
          FileUtils.touch( import_path.join('a.html') )
          FileUtils.mkdir_p(import_path.join('no_import'))
          FileUtils.touch(import_path.join('no_import/no.html'))
        end

        it 'ディレクトリは取り込まれること' do
          expect do
            subject.import
          end.to change(Genre, :count).by(1)
          expect(Genre.where(name: import_dirname, parent_id: genre.id)).to exist
        end

        it 'サブディレクトリは取り込まれないこと' do
          expect(Genre.where(name: 'no_import')).to_not exist
        end

        it 'HTMLファイルは取り込まれないこと' do
          expect do
            expect do
              subject.import
            end.to change(PageContent, :count).by(0)
          end.to change(Page, :count).by(0)
        end

        it 'メッセージは無いこと' do
          subject.import
          expect(subject.messages).to have(:no).items
        end
      end

      context 'インポートするディレクトリ直下に1つでもHTMLファイル(.htm)が存在する場合' do
        before do
          FileUtils.touch( import_path.join('b.htm') )
          FileUtils.mkdir_p(import_path.join('no_import'))
          FileUtils.touch(import_path.join('no_import/no.html'))
        end

        it 'ディレクトリは取り込まれること' do
          expect do
            subject.import
          end.to change(Genre, :count).by(1)
          expect(Genre.where(name: import_dirname, parent_id: genre.id)).to exist
        end

        it '戻り値は取り込んだディレクトリのGenreであること' do
          actual = subject.import
          expect(actual).to be_instance_of(Genre)
          expect(actual.attributes).to include(
            { 'name' => import_dirname,
              'title' => import_dirname,
              'parent_id' => genre.id,
            }
          )
        end

        it 'サブディレクトリは取り込まれないこと' do
          expect(Genre.where(name: 'no_import')).to_not exist
        end

        it 'HTMLファイルは取り込まれないこと' do
          expect do
            expect do
              subject.import
            end.to change(PageContent, :count).by(0)
          end.to change(Page, :count).by(0)
        end

        it 'メッセージは無いこと' do
          subject.import
          expect(subject.messages).to have(:no).items
        end
      end

      context 'インポートするディレクトリ直下にHTMLファイル(.html, .htm)が存在しない場合' do
        before do
          FileUtils.rm_f( import_path.join('*.{html,htm}') )
          FileUtils.mkdir_p(import_path.join('no_import'))
          FileUtils.touch(import_path.join('no_import/no.html'))
        end

        it 'ディレクトリは取り込まれないこと' do
          expect do
            subject.import
          end.to change(Genre, :count).by(0)
          expect(Genre.where(name: import_dirname, parent_id: genre.id)).to_not exist
        end

        it '戻り値は nil であること' do
          expect(subject.import).to be_nil
        end

        it 'メッセージが追加されること' do
          subject.import
          expect(subject.messages).to have(1).items
        end
      end

      context 'インポートするディレクトリが存在しない場合' do
        before do
          FileUtils.rm_f( import_path )
        end

        it 'ディレクトリは取り込まれないこと' do
          expect do
            subject.import
          end.to change(Genre, :count).by(0)
        end

        it '戻り値は nil であること' do
          expect(subject.import).to be_nil
        end

        it 'メッセージが追加されること' do
          subject.import
          expect(subject.messages).to have(1).items
        end
      end
    end
  end
end
