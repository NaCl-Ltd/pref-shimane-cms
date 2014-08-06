require 'spec_helper'

describe WebMonitor do

  describe 'バリデーション' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :login }
    it { should validate_uniqueness_of(:login).scoped_to(:genre_id) }
    it { should ensure_length_of(:login).is_at_least(3).is_at_most(20) }

    context "if password_validation_required?=true" do
      before { allow(subject).to receive(:password_validation_required?).and_return(true) }

      it { should validate_presence_of :password }
      it { should ensure_length_of(:password).is_at_least(6).is_at_most(12) }
      it { should validate_confirmation_of(:password) }
      it { should validate_presence_of :password_confirmation }
    end

    context "if password_validation_required?=false" do
      before { allow(subject).to receive(:password_validation_required?).and_return(false) }

      it { should_not validate_presence_of :password }
      it { should_not ensure_length_of(:password).is_at_least(6).is_at_most(12) }
      it { should_not validate_confirmation_of(:password) }
      it { should_not validate_presence_of :password_confirmation }
    end

    context "if persisted?=true" do
      before { allow(subject).to receive(:persisted?).and_return(true) }

      context "if login_changed?=true && password_changed?=true" do
        before do
          allow(subject).to receive(:login_changed?).and_return(true)
          allow(subject).to receive(:password_changed?).and_return(true)
        end
        it ':login_changed メッセージはないこと' do
          expect(subject.errors_on(:base)).to_not include(generate_error_message(:base, :login_changed))
        end
      end

      context "if login_changed?=true && password_changed?=false" do
        before do
          allow(subject).to receive(:login_changed?).and_return(true)
          allow(subject).to receive(:password_changed?).and_return(false)
        end
        it ':login_changed メッセージは有ること' do
          expect(subject.errors_on(:base)).to include(generate_error_message(:base, :login_changed))
        end
      end

      context "if login_changed?=false && password_changed?=true" do
        before do
          allow(subject).to receive(:login_changed?).and_return(false)
          allow(subject).to receive(:password_changed?).and_return(true)
        end
        it ':login_changed メッセージはないこと' do
          expect(subject.errors_on(:base)).to_not include(generate_error_message(:base, :login_changed))
        end
      end

      context "if login_changed?=false && password_changed?=false" do
        before do
          allow(subject).to receive(:login_changed?).and_return(false)
          allow(subject).to receive(:password_changed?).and_return(false)
        end
        it ':login_changed メッセージはないこと' do
          expect(subject.errors_on(:base)).to_not include(generate_error_message(:base, :login_changed))
        end
      end
    end

    context "if persisted?=false && login_changed?=true && password_changed?=false" do
      before do
        allow(subject).to receive(:persisted?).and_return(false)
        allow(subject).to receive(:login_changed?).and_return(true)
        allow(subject).to receive(:password_changed?).and_return(false)
      end
      it ':login_changed メッセージはないこと' do
        expect(subject.errors_on(:base)).to_not include(generate_error_message(:base, :login_changed))
      end
    end
  end

  describe 'メソッド' do
    before do
      Kernel.stub(:rand).with(anything) { 1 }
    end

    it { should respond_to :password_confirmation, :password_confirmation= }
    describe '.htpasswd' do
      it '暗号化されたパスワードが返ること' do
        expect(described_class.htpasswd('password')).to eq(
          "BBUTgMrYjsT0."
        )
      end
    end

    describe 'import_csv!' do
      let!(:genre) { create(:genre) }
      let(:csv_data) do
        CSV.generate do |csv|
          csv << %w(Aaron aaron password)
          csv << %w(Quentin quentin 12345678)
          csv << %w(Rails rails RubyonRails)
        end
      end

      before do
        WebMonitor.delete_all
      end

      it '人数分、登録されること' do
        expect do
          described_class.import_csv!(csv_data, genre: genre)
        end.to change(WebMonitor, :count).by(3)
      end

      it 'CSVの内容は各属性に設定されること' do
        described_class.import_csv!(csv_data, genre: genre)
        monitors = WebMonitor.order(:id).to_a
        expect(monitors[0].attributes).to include(
          {name: 'Aaron', login: 'aaron', password: WebMonitor.htpasswd('password'), genre_id: genre.id, state: WebMonitor.status[:edited]}.stringify_keys
        )
        expect(monitors[1].attributes).to include(
          {name: 'Quentin', login: 'quentin', password: WebMonitor.htpasswd('12345678'), genre_id: genre.id, state: WebMonitor.status[:edited]}.stringify_keys
        )
        expect(monitors[2].attributes).to include(
          {name: 'Rails', login: 'rails', password: WebMonitor.htpasswd('RubyonRails'), genre_id: genre.id, state: WebMonitor.status[:edited]}.stringify_keys
        )
      end
    end

    describe 'import_csv_from!' do
      let!(:genre) { create(:genre) }
      let(:csv_data) do
        CSV.generate do |csv|
          csv << %w(Aaron aaron password)
          csv << %w(Quentin quentin 12345678)
          csv << %w(Rails rails RubyonRails)
        end
      end
      let(:csv_file) do
        Tempfile.new(%w{t, .csv}).tap do |_csv_file|
          _csv_file.write(NKF.nkf('-We', csv_data))
          _csv_file.rewind
        end
      end

      before do
        WebMonitor.delete_all
      end

      after do
        csv_file.close!
      end

      it '.import_csv を呼び出すこと' do
        expect(described_class).to receive(:import_csv!).with(csv_data, {genre: genre})
        described_class.import_csv_from!(csv_file, genre: genre)
      end
    end

    describe '.reflect_web_monitors_of' do
      let!(:genre) { create(:genre) }
      let!(:other_genre) { create(:genre) }

      before do
        FactoryGirl.with_options(genre: genre) do |f|
          f.create_list(:web_monitor, 1, state: described_class.status[:registered])
          f.create_list(:web_monitor, 2, state: described_class.status[:edited])
        end
        FactoryGirl.with_options(genre: other_genre) do |f|
          f.create_list(:web_monitor, 2, state: described_class.status[:edited])
        end
      end

      it 'create_htpasswd ジョブが登録されること' do
        expect do
          described_class.reflect_web_monitors_of(genre)
        end.to change{Job.where(action: 'create_htpasswd', arg1: genre.id.to_s).count}.by(1)
      end

      it 'genreに紐づくWebMonitorレコードのstate属性が:registeredに変更されること' do
        expect do
          expect do
            described_class.reflect_web_monitors_of(genre)
          end.to change{genre.web_monitors.eq_registered.count}.by(2)
        end.to change{other_genre.web_monitors.eq_registered.count}.by(0)
      end
    end

    describe '#password_validation_required?' do
      { {new_record?: true,  password_changed?: true,  password_confirmation: ''}  => true,
        {new_record?: true,  password_changed?: false, password_confirmation: ''}  => true,
        {new_record?: true,  password_chagned?: true,  password_confirmation: 'a'} => true,
        {new_record?: true,  password_changed?: false, password_confirmation: 'a'} => true,
        {new_record?: false, password_changed?: true,  password_confirmation: ''}  => true,
        {new_record?: false, password_changed?: false, password_confirmation: ''}  => false,
        {new_record?: false, password_changed?: true,  password_confirmation: 'a'} => true,
        {new_record?: false, password_changed?: false, password_confirmation: 'a'} => true,
      }.each do |key, value|
        new_record, password_changed, password_confirmation = key.values_at(:new_record?, :password_changed?, :password_confirmation)
        context %{if new_record?=#{new_record}, password_changed?="#{password_changed}", password_confirmation="#{password_confirmation}"} do
          before do
            subject.assign_attributes(password_confirmation: password_confirmation)
            allow(subject).to receive(:new_record?).and_return(new_record)
            allow(subject).to receive(:password_changed?).and_return(password_changed)
          end
          it %{#{value} を返すこと} do
            expect(subject.send(:password_validation_required?)).to eq value
          end
        end
      end
    end

    describe '#password_change_tried?' do
      { {password: 'a', password_confirmation: 'a'} => true,
        {password: 'a', password_confirmation: ''}  => true,
        {password: '',  password_confirmation: 'a'} => true,
        {password: '',  password_confirmation: ''}  => false,
      }.each do |key, value|
        password, password_confirmation = key.values_at(:password, :password_confirmation)
        context %{if password="#{password}", password_confirmation="#{password_confirmation}"} do
          before do
            subject.assign_attributes(password: password, password_confirmation: password_confirmation)
          end
          it %{#{value} を返すこと} do
            expect(subject.send(:password_change_tried?)).to eq value
          end
        end
      end
    end

    describe '#auth_data_changed?' do
      { {login_changed?: true,  password_changed?: true}  => true,
        {login_changed?: true,  password_changed?: false} => true,
        {login_changed?: false, password_changed?: true}  => true,
        {login_changed?: false, password_changed?: false} => false,
      }.each do |key, value|
        login_changed, password_changed = key.values_at(:login_changed?, :password_changed?)
        context %{if login_changed?=#{login_changed}, password_changed?=#{password_changed}} do
          before do
            allow(subject).to receive(:login_changed?).and_return(login_changed)
            allow(subject).to receive(:password_changed?).and_return(password_changed)
          end
          it %{#{value} を返すこと} do
            expect(subject.send(:auth_data_changed?)).to eq value
          end
        end
      end
    end

    describe '#undo_password' do
      subject { create(:web_monitor, password: 'password') }

      it '変更されたパスワードが元に戻ること' do
        pass = subject.password
        subject.password = '1234'
        subject.send(:undo_password)
        expect(subject.password).to eq pass
      end
    end

    describe '#mark_edited' do
      it 'status[:edited] に変更されること' do
        subject.state = nil
        subject.send(:mark_edited)
        expect(subject.state).to eq described_class.status[:edited]
      end
    end

    describe '#crypt_password' do
      subject { build(:web_monitor, login: 'aaron') }

      it '暗号化パスワードに変更されること' do
        subject.password = 'password'
        subject.send(:crypt_password)
        expect(subject.password).to eq described_class.htpasswd('password')
      end
    end

    describe '#htpasswd' do
      subject { build(:web_monitor, login: 'aaron') }

      it '暗号化パスワードを返すこと' do
        expect(subject.send(:htpasswd, 'password')).to eq described_class.htpasswd('password')
      end
    end

    describe '#update_htpasswd' do
      subject { build(:web_monitor, login: 'aaron') }

      context 'フォルダのアクセス制御が有効である場合' do
        before do
          subject.genre.update_column(:auth, true)
        end

        it 'remove_from_htpasswdジョブが登録されること' do
          expect do
            subject.send(:update_htpasswd)
          end.to change{ Job.where(action: 'remove_from_htpasswd', arg1: subject.genre_id.to_s, arg2: 'aaron').count }.by(1)
        end
      end

      context 'フォルダのアクセス制御が無効である場合' do
        before do
          subject.genre.update_column(:auth, false)
        end

        it 'ジョブは登録されないこと' do
          expect do
            subject.send(:update_htpasswd)
          end.to change{ Job.count }.by(0)
        end
      end
    end
  end

  def generate_error_message(attr, msg, options = {})
    ActiveModel::Errors.new(described_class.new).send(:normalize_message, attr, msg, options)
  end
end
