require 'spec_helper'

describe Susanoo::ServerSync do
  describe "module function" do
    subject{ Susanoo::ServerSync }

    it { should respond_to :logger }
    it { should respond_to :logger= }
    it { should respond_to :sync_enabled? }

    describe ".logger" do
      context "logger = nil の場合" do
        before do
          subject.logger = nil
        end

        it "Susanoo::ServerSync::NULL_LOGGER を返すこと" do
          expect(subject.logger).to eq Susanoo::ServerSync::NULL_LOGGER
        end
      end

      context "logger = Logger.new の場合" do
        let(:logger) { Logger.new(IO::NULL) }

        before do
          subject.logger = logger
        end

        it "設定したロガーを返すこと" do
          expect(subject.logger).to eq logger
          expect(logger).to_not eq Susanoo::ServerSync::NULL_LOGGER
        end
      end
    end

    describe ".sync_enabled?" do
      it "\#{Settings.export.sync_enable_file_path} のファイルが存在する場合、true を返すこと" do
        allow(Settings.export).to receive(:sync_enable_file_path).and_return(__FILE__)
        expect(subject.send(:sync_enabled?)).to be_true
      end

      it "\#{Settings.export.sync_enable_file_path} のファイルが存在しない場合、false を返すこと" do
        allow(Settings.export).to receive(:sync_enable_file_path).and_return(File.join(__FILE__, 'miss'))
        expect(subject.send(:sync_enabled?)).to be_false
      end
    end
  end
end
