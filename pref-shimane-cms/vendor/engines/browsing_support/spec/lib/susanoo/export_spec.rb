require 'spec_helper'

describe "Susanoo::Export" do
  subject { Susanoo::Export.new }

  describe '拡張' do
    it 'move_mp3 メソッドが定義されていること' do
      expect(subject.public_methods).to include :move_mp3
    end

    it 'action_methods に move_mp3 があること' do
      expect(subject.class.action_methods).to include "move_mp3"
    end
  end

  describe 'メソッド' do
    describe '#move_mp3' do
      before do
        BrowsingSupport::Exports::Mp3Mover.any_instance.stub(:move)
      end

      it 'BrowsingSupport::Exports::Mp3Mover#move が呼び出されること' do
        expect_any_instance_of(BrowsingSupport::Exports::Mp3Mover).to receive(:move).with('/hoge/foo.html', 't123')
        subject.move_mp3('/hoge/foo.html', 't123')
      end

      it 'BrowsingSupport::Exports::Mp3Mover#logger= が呼び出されること' do
        expect_any_instance_of(BrowsingSupport::Exports::Mp3Mover).to receive(:logger=).with(subject.logger)
        subject.move_mp3('/hoge/foo.html', 't123')
      end
    end
  end
end
