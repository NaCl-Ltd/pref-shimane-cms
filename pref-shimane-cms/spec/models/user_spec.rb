require 'spec_helper'
require "digest/sha1"

describe User do
  describe "バリデーション" do
    it { should validate_presence_of :login }
    it { should validate_uniqueness_of :login }
    it { should ensure_length_of(:login).is_at_least(3).is_at_most(20) }
    it { should validate_presence_of :password }
    it { should ensure_length_of(:password).is_at_least(8).is_at_most(12) }
    it { should validate_presence_of :name }
    it { should validate_presence_of :section_id }
    it { should validate_presence_of :authority }

    describe 'password_confirmation' do
      context "if password_changed?=true" do
        subject {
          User.new(login: "test01", name: "test01", password: "password", password_confirmation: "paxxword")
        }
        it { should have(1).errors_on(:password_confirmation) }
      end

      context "if password_changed?=false" do
        before {
          allow(subject).to receive(:password_changed?).and_return(false)
        }
        it { should_not validate_confirmation_of(:password_confirmation) }
      end
    end
  end

  describe "メソッド" do
    describe ".authenticate" do
      before do
        @user = create(:user)
      end

      it "認証に成功した場合、Userを返すこと" do
        user = User.authenticate(login: @user.login, password: "password")

        expect(user).not_to be_nil
        expect(user.login).to eq @user.login
      end

      it "認証に失敗した場合、nilを返すこと" do
        user = User.authenticate(login: @user.login, password: "paxxword")
        expect(user).to be_nil
      end

      it "ユーザ名が未指定の場合、nilを返すこと" do
        user = User.authenticate(password: "paxxword")
        expect(user).to be_nil
      end

      it "パスワードが未指定の場合、nilを返すこと" do
        user = User.authenticate(login: @user.login)
        expect(user).to be_nil
      end
    end

    describe ".encrypt" do
      it "指定した文字列が暗号化されること" do
        text = "password"
        expect(User.encrypt(text)).to eq Digest::SHA1.hexdigest("#{User.salt}--#{text}--")
      end
    end

    describe "#encrypt_password" do
      before do
        @user = create(:user, password: "password")
      end

      it "ユーザを保存する際にパスワードが暗号化されていること" do
        expect(@user.password).to eq User.encrypt("password")
      end
    end

    describe ".authorizer_or_admin?" do
      shared_examples_for "ユーザ権限毎の検証" do |authority, name, result|
        it "#{name}の場合,#{result}が返ること" do
          user = create(:user, authority: authority)
          expect(user.authorizer_or_admin?).to eq(result)
        end
      end
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor], "ホームページ担当者", false)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", true)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin], "運用管理者", true)
    end

    describe ".admin?" do
      shared_examples_for "ユーザ権限毎の検証" do |authority, name, result|
        it "#{name}の場合,#{result}が返ること" do
          user = create(:user, authority: authority)
          expect(user.admin?).to eq(result)
        end
      end
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor], "ホームページ担当者", false)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", false)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin], "運用管理者", true)
    end


    describe ".authorizer?" do
      shared_examples_for "ユーザ権限毎の検証" do |authority, name, result|
        it "#{name}の場合,#{result}が返ること" do
          user = create(:user, authority: authority)
          expect(user.authorizer?).to eq(result)
        end
      end
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor], "ホームページ担当者", false)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", true)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin], "運用管理者", false)
    end


    describe ".editor?" do
      shared_examples_for "ユーザ権限毎の検証" do |authority, name, result|
        it "#{name}の場合,#{result}が返ること" do
          user = create(:user, authority: authority)
          expect(user.editor?).to eq(result)
        end
      end
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor], "ホームページ担当者", true)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", false)
      it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin], "運用管理者", false)
    end


    describe ".skip_accessibility_check?" do

      shared_examples_for "ユーザ権限毎の検証" do |authority, name, result|
        it "#{name}の場合,#{result}が返ること" do
          user = create(:user, authority: authority, section: section)
          expect(user.skip_accessibility_check?).to eq(result)
        end
      end

      context "アクセシビリティチェックスキップ設定(Settings.page_content.unchecked)が true の場合" do
        before do
          Settings.page_content.unchecked = true
        end

        context "所属のアクセシビリティチェック設定が「チェック不要」の場合" do
          let(:section) { create(:section, skip_accessibility_check: true) }

          it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor]    , "ホームページ担当者", true)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", true)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin]     , "運用管理者", true)
        end

        context "所属のアクセシビリティチェック設定が「チェック必須」の場合" do
          let(:section) { create(:section, skip_accessibility_check: false) }

          it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor]    , "ホームページ担当者", false)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", false)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin]     , "運用管理者", true)
        end
      end

      context "アクセシビリティチェックスキップ設定(Settings.page_content.unchecked)が false の場合" do
        before do
          Settings.page_content.unchecked = false
        end

        context "所属のアクセシビリティチェック設定が「チェック不要」の場合" do
          let(:section) { create(:section, skip_accessibility_check: true) }

          it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor]    , "ホームページ担当者", false)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", false)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin]     , "運用管理者", false)
        end

        context "所属のアクセシビリティチェック設定が「チェック必須」の場合" do
          let(:section) { create(:section, skip_accessibility_check: false) }

          it_behaves_like("ユーザ権限毎の検証", User.authorities[:editor]    , "ホームページ担当者", false)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:authorizer], "情報提供管理者", false)
          it_behaves_like("ユーザ権限毎の検証", User.authorities[:admin]     , "運用管理者", false)
        end
      end
    end
  end
end
