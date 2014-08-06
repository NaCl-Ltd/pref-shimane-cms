require 'spec_helper'

describe Susanoo::ServerSync::Backend::Rsync do
  subject { Susanoo::ServerSync::Backend::Rsync.new }

  describe "メソッド" do
    before do
      allow(Susanoo::ServerSync::Backend::Rsync).to receive(:rsync).and_return(['', 0])
    end

    describe "#push" do
      let(:src)  { '/path/to/src/' }
      let(:dest) { '/path/to/dest' }
      let(:user)   { 'sync_user' }
      let(:server) { '127.0.0.1' }

      context "rsync の exitcode が 0 の場合" do
        it "Rsync::Result#success? はtrue を返すこと" do
          allow(Susanoo::ServerSync::Backend::Rsync).to receive(:rsync).and_return(['', 0])
          result = subject.push(src: src, dest: dest)

          expect(result.success?).to be_true
        end
      end

      context "rsync の exitcode が 1 の場合" do
        it "Rsync::Result#success? はfalse を返すこと" do
          allow(Susanoo::ServerSync::Backend::Rsync).to receive(:rsync).and_return(['', 1])
          result = subject.push(src: src, dest: dest)

          expect(result.success?).to be_false
        end
      end

      it "Rsync::Result#output は Rsync#rsync の戻り値が設定されること" do
        allow(Susanoo::ServerSync::Backend::Rsync).to receive(:rsync).and_return(["a\n0", 0])

        result = subject.push(src: src, dest: dest)
        expect(result.output).to eq "a\n0"
        expect(result.exitcode).to eq 0
      end

      context "user, server を渡す場合" do
        it "destination は <user>@<server>:<dest> の形式になること" do
          expect(subject.class).to receive(:rsync).with(src, "#{user}@#{server}:#{dest}", {})

          subject.push(src: src, dest: dest, user: user, server: server)
        end
      end

      context "server を渡す場合" do
        it "destination は <server>:<dest> の形式になること" do
          expect(subject.class).to receive(:rsync).with(src, "#{server}:#{dest}", {})

          subject.push(src: src, dest: dest, server: server)
        end
      end
    end
  end
end
