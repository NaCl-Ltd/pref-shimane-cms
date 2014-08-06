require 'spec_helper'

describe Susanoo::ServerSync::Helpers::Loggable do

  class LoggableIncluded
    include Susanoo::ServerSync::Helpers::Loggable
  end

  subject{ LoggableIncluded.new }

  describe "クラスメソッド" do
    subject{ LoggableIncluded }

    it { should respond_to :logger }
    it { should respond_to :logger= }
    it { should respond_to :_logger }
    it { should respond_to :_logger= }

    describe "logger" do
      let(:server_sync_logger) { Logger.new(IO::NULL) }

      before do
        allow(Susanoo::ServerSync).to receive(:logger).and_return(server_sync_logger)
      end

      context "logger = nil の場合" do
        before do
          subject.logger = nil
        end

        it "Susanoo::ServerSync.logger の値を返すこと" do
          expect(subject.logger).to eq server_sync_logger
        end
      end

      context "logger = Logger.new の場合" do
        let(:logger) { Logger.new(IO::NULL) }

        before do
          subject.logger = logger
        end

        it "設定したロガーを返すこと" do
          expect(subject.logger).to eq logger
          expect(logger).to_not eq server_sync_logger
        end
      end
    end
  end

  describe "メソッド" do
    it { should respond_to :logger }
    it { should respond_to :logger= }
    it { should respond_to :_logger }
    it { should respond_to :_logger= }

    describe "logger" do
      let(:server_sync_logger) { Logger.new(IO::NULL) }

      before do
        allow(Susanoo::ServerSync).to receive(:logger).and_return(server_sync_logger)
      end

      context "logger = nil の場合" do
        before do
          subject.logger = nil
        end

        it "Susanoo::ServerSync.logger の値を返すこと" do
          expect(subject.logger).to eq server_sync_logger
        end
      end

      context "logger = Logger.new の場合" do
        let(:logger) { Logger.new(IO::NULL) }

        before do
          subject.logger = logger
        end

        it "設定したロガーを返すこと" do
          expect(subject.logger).to eq logger
          expect(logger).to_not eq server_sync_logger
        end
      end
    end
  end
end
