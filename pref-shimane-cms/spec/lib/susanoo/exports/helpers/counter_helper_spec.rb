require 'spec_helper'

describe Susanoo::Exports::Helpers::CounterHelper do
  include Susanoo::Exports::Helpers::CounterHelper

  before do
    allow_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:log).and_return(true)
  end

  describe ".included" do
    context "ファイルが存在しない場合" do
      before do
        FileUtils.rm_rf(Susanoo::Exports::Helpers::CounterHelper::DIR)
        Susanoo::Exports::Helpers::CounterHelper.included(String)
      end

      it "ファイルが作成されていること" do
        expect(FileTest.exists?(Susanoo::Exports::Helpers::CounterHelper::DIR)).to be_true
      end
    end
  end

  describe "#create_counter" do
    let(:top_genre) { create(:top_genre) }
    let(:page) { create(:page, genre_id: top_genre.id) }

    context "ファイルが存在しない場合" do
      before :each do
        @path = Susanoo::Exports::Helpers::CounterHelper::DIR.join(page.id.to_s)
        File.delete(@path) if FileTest.exists?(@path)
      end

      it "カウンターファイルを作成していること" do
        allow_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:sync_counter).and_return(true)
        create_counter(page.path)
        expect(FileTest.exists?(@path)).to be_true
      end

      it "パーミッションが正しいこと" do
        allow_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:sync_counter).and_return(true)
        create_counter(page.path)
        stat = File::stat(@path)
        mode = "%o" % stat.mode
        expect(mode[-3, 3]).to eq('664')
      end

      it "#sync_counterメソッドを正しく呼び出していること" do
        expect(self).to receive(:sync_counter).with(page.id.to_s)
        create_counter(page.path)
      end

      context "start_countを指定した場合" do
        let(:start_count) { "10" }

        it "カウンターファイルを作成していること" do
          allow_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:sync_counter).and_return(true)
          create_counter(page.path, start_count)
          expect(File.read(@path)).to eq(start_count)
        end
      end
    end
  end

  describe "#remove_counter" do
    let(:top_genre) { create(:top_genre) }
    let(:page) { create(:page, genre_id: top_genre.id) }

    context "ファイルが存在する場合" do
      before :each do
        @path = Susanoo::Exports::Helpers::CounterHelper::DIR.join(page.id.to_s)
        File.open(@path, 'w'){|f| f.print('test')}
      end

      it "ファイルが削除されること" do
        allow_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:sync_counter).and_return(true)
        remove_counter(page.path)
        expect(FileTest.exists?(@path)).to be_false
      end

      it "#sync_counterメソッドを正しく呼び出していること" do
        expect(self).to receive(:sync_counter).with(page.id.to_s)
        remove_counter(page.path)
      end
    end
  end

  describe "#create_or_remove_coutner" do
    let(:top_genre) { create(:top_genre) }
    let(:page) { create(:page, genre_id: top_genre.id) }

    context "HTML内にカウンターが含まれる場合" do
      before do
        allow_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:get_counter).and_return(10)
      end

      it "#create_couterメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:create_counter)
        create_or_remove_counter("", page.path)
      end
    end

    context "HTML内にカウンターが含まれない場合" do
      before do
        allow_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:get_counter).and_return(false)
      end

      it "#remove_counterメソッドを呼び出していること" do
        expect_any_instance_of(Susanoo::Exports::Helpers::CounterHelper).to receive(:remove_counter)
        create_or_remove_counter("", page.path)
      end
    end
  end

  describe "#get_counter" do
    let(:count) { "10" }

    before do
      @html = "#{Settings.counter.url}count.cgi?id=1&amp;start=#{count}"
    end

    it "カウンターの数を返すこと" do
      expect(get_counter(@html)).to eq(count)
    end
  end

  describe "#counter_file" do
    context "Pageが存在する場合" do
      let(:top_genre) { create(:top_genre) }
      let(:page) { create(:page, genre_id: top_genre.id) }

      before do
        @path = Susanoo::Exports::Helpers::CounterHelper::DIR.join(page.id.to_s)
      end

      context "ファイルが存在しない場合" do
        before do
          File.delete(@path) if FileTest.exists?(@path)
        end

        it "ブロックの第一引数がfalseであること" do
          counter_file(page.path) do |exists, path|
            expect(exists).to be_false
          end
        end

        it "ブロックの第二引数がパスであること" do
          counter_file(page.path) do |exsits, path|
            expect(path).to eq(@path)
          end
        end
      end

      context "ファイルが存在する場合" do
        before do
          File.open(@path, 'w'){|f| f.print('test')}
        end

        it "ブロックの第一引数がfalseであること" do
          counter_file(page.path) do |exists, path|
            expect(exists).to be_true
          end
        end
      end
    end

    context "Pageが存在しない場合" do
      it "falseを返すこと" do
        expect(counter_file('/path/path/test')).to be_false
      end
    end
  end
end
