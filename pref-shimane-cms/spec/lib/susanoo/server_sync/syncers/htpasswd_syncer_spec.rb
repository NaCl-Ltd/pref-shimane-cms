require 'spec_helper'

describe Susanoo::ServerSync::Syncers::HtpasswdSyncer do
  describe "メソッド" do
    let(:server) { 'localhost' }
    subject { Susanoo::ServerSync::Syncers::HtpasswdSyncer.new(server) }

    it { should respond_to(:src) }
    it { should respond_to(:dest) }
    it { should respond_to(:user) }
    it { should respond_to(:priority) }

    describe "#src" do
      it "'\#{Settings.export.local_htpasswd_dir}/' が返ること" do
        allow(Settings.export).to receive(:local_htpasswd_dir).and_return('/path/to/dir')
        expect(subject.src).to eq '/path/to/dir/'
      end
    end

    describe "#dest" do
      it "'\#{Settings.export.public_htpasswd_dir}/' が返ること" do
        allow(Settings.export).to receive(:public_htpasswd_dir).and_return('/path/to/dir')
        expect(subject.dest).to eq '/path/to/dir/'
      end
    end

    describe "#user" do
      it "'\#{Settings.export.user}' が返ること" do
        allow(Settings.export).to receive(:user).and_return('sync_user')
        expect(subject.user).to eq 'sync_user'
      end
    end

    describe "#priority" do
      it "10 が返ること" do
        expect(subject.priority).to eq 10
      end
    end
  end
end

