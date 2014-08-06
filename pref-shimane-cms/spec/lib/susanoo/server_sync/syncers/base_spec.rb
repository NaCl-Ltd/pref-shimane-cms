require 'spec_helper'

describe Susanoo::ServerSync::Syncers::Base do
  describe "メソッド" do
    let(:server) { 'localhost' }
    subject { Susanoo::ServerSync::Syncers::Base.new(server) }

    it { should respond_to(:src) }
    it { should respond_to(:dest) }
    it { should respond_to(:user) }
    it { should respond_to(:priority) }

    describe "#src" do
      it 'nil を返すこと' do
        expect(subject.src).to be_nil
      end
    end

    describe "#dest" do
      it 'nil を返すこと' do
        expect(subject.dest).to be_nil
      end
    end

    describe "#user" do
      it 'nil を返すこと' do
        expect(subject.user).to be_nil
      end
    end

    describe "#priority" do
      it '20 を返すこと' do
        expect(subject.priority).to eq 20
      end
    end

    describe "#run" do
      before do
        result = double('backend/rsync/result', exitcode: 0, success?: true)
        allow_any_instance_of(Susanoo::ServerSync::Backend::Rsync).to receive(:push).and_return(result)
      end

      context "subject#sync_files が空の場合" do
        it "ServerSync::Backend::Rsync#push を呼ばないこと" do
          expect_any_instance_of(Susanoo::ServerSync::Backend::Rsync).to_not receive(:push)

          subject.run
        end

        it "true を返すこと" do
          expect(subject.run).to be_true
        end
      end

      context "subject#sync_files に同期対象のファイルが設定されていた場合" do
        before do
          allow(subject).to receive(:user).and_return('sync_user')
          allow(subject).to receive(:sync_files).and_return(%w(
            /dir100/index.*
            /dir100/page1.**
            /dir200/dir220/dir221/index.*
            /dir200/dir220/dir221/page221_1.*
            /dir400/dir420/dir428/index.**
            /dir500/*.html
            /dir600/
          ))
        end

        it "ServerSync::Backend::Rsync#push に引数を与えて、呼び出すこと" do
          expect_any_instance_of(Susanoo::ServerSync::Backend::Rsync).to receive(:push).with({
            server: server,
            user: 'sync_user',
            options: [
              "-aLz",
              "-e 'ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=3'",
              "--delete-after",
              "--include-from=-",
              "--exclude=*",
            ]
          },{
            stdin_data: %w[
                /
                /dir100
                /dir100/index.**
                /dir100/page1.**
                /dir200
                /dir200/dir220
                /dir200/dir220/dir221
                /dir200/dir220/dir221/index.**
                /dir200/dir220/dir221/page221_1.**
                /dir400
                /dir400/dir420
                /dir400/dir420/dir428
                /dir400/dir420/dir428/index.**
                /dir500
                /dir500/*.html
                /dir600
                /dir600/**
              ].join("\n")
          })

          subject.run
        end

        context "ServerSync::Backend::Rsync#push が成功した場合" do
          let(:result) { double('backend/rsync/result', exitcode: 0, success?: true) }

          before do
            allow_any_instance_of(Susanoo::ServerSync::Backend::Rsync).to receive(:push).and_return(result)
          end

          it "true を返すこと" do
            expect(subject.run).to be_true
          end

          it "Backend::Rsync::Result#output メソッドは呼ばないこと" do
            expect(result).to_not receive(:output)
            subject.run
          end
        end

        context "ServerSync::Backend::Rsync#push が失敗する場合" do
          let(:result) { double('backend/rsync/result', exitcode: 30, success?: false, output: 'Error') }

          before do
            allow_any_instance_of(Susanoo::ServerSync::Backend::Rsync).to receive(:push).and_return(result)
          end

          it "false を返すこと" do
            expect(subject.run).to be_false
          end

          it "Backend::Rsync::Result#output メソッドを呼ぶこと" do
            expect(result).to receive(:output)
            subject.run
          end
        end
      end
    end
  end
end
