require 'spec_helper'

describe "BrowsingSupport::Exports::Helpers::PathHelper" do
  subject do
    Class.new do
      include BrowsingSupport::Exports::Helpers::PathHelper
    end.new
  end

  describe '拡張' do
    it 'Susanoo::Exports::Helpers::PathHelper が include されていること' do
      expect(subject.class).to include Susanoo::Exports::Helpers::PathHelper
    end
  end

  describe 'メソッド' do
    describe '#arg_to_path' do
      context '存在するページの id を指定する場合' do
        let(:page) { create(:page).reload }

        it 'ページのパスが返ること' do
          expect(subject.arg_to_path("p:#{page.id}")).to eq Pathname.new(File.join('/', page.path))
        end
      end

      context '存在しないページの id を指定する場合' do
        it 'ActiveRecord::RecordNotFound が発生すること' do
          expect do
            subject.arg_to_path("p:0")
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context '存在するフォルダの id を指定する場合' do
        let(:genre) { create(:genre).reload }

        it 'フォルダの index.html のパスが返ること' do
          expect(subject.arg_to_path("g:#{genre.id}")).to eq Pathname.new(File.join('/', genre.path, "index.html"))
        end
      end

      context '存在しないフォルダの id を指定する場合' do
        it 'ActiveRecord::RecordNotFound が発生すること' do
          expect do
            subject.arg_to_path("g:0")
          end.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'ページのパスを指定する場合' do
        it 'ページのパスが返ること' do
          expect(subject.arg_to_path("/hoge/foo.html")).to eq Pathname.new("/hoge/foo.html")
        end
      end

      context 'ディレクトリパスを指定する場合' do
        it '指定したディレクトリの index.html のパスが返ること' do
          expect(subject.arg_to_path("/hoge/foo/")).to eq Pathname.new("/hoge/foo/index.html")
        end
      end
    end
  end
end
