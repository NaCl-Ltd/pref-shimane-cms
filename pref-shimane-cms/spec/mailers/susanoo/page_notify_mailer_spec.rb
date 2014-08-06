require "spec_helper"

describe Susanoo::PageNotifyMailer do
  before do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @division = create(:division)
    @section = create(:section, division: @division)
    @editor = create(:user, authority: 0, section: @section, mail: 'editor@example.com')
    @authorizer = create(:user, authority: 1, section: @section, mail: 'authorizer@example.com')
  end

  let(:domain) { Susanoo::PageNotifyMailer::DOMAIN.dup.delete('@') }

  describe 'publish_request' do
    context "公開依頼メールの共通確認項目" do
      before do
        @now = Time.new(2013,4,1)
        Timecop.freeze(@now)

        @genre = create(:genre, section: @section)
        @page = create(:page_request, genre: @genre)
        @page_content = @page.request_content
        @page_content.user_name = '編集者'
        @page_content.tel = '0852-28-9280'
        @page_content.email = 'nacl'
        @page_content.comment = 'コメント'
        @mail = Susanoo::PageNotifyMailer.publish_request(@editor, @page_content)
      end

      after { Timecop.return }

      it "公開依頼メールを送信できること" do
        @mail.deliver!
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end

      it "送信先が情報提供管理者になること" do
        expect(@mail.to).to eq([@authorizer.mail])
      end

      it "件名が正しいこと" do
        mail_subject = NKF.nkf('-mw', @mail.subject)
        expect(mail_subject).to eq("CMS #{I18n.t('mail.page_notify.publish_request.subject')}(#{@page.title})")
      end

      it "メール本文にページ編集者の名前が含まれること" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include(@page_content.user_name)
      end

      it "メール本文にページ編集者の電話番号が含まれること" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include(@page_content.tel)
      end

      it "メール本文にページ編集者のメールアドレスが含まれること" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include("#{@page_content.email}@#{Settings.mail.domain}")
      end

      it "メール本文にページ編集時のコメントが含まれること" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include(@page_content.comment)
      end

      it "メール本文に依頼時刻が含まれること" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include(@now.strftime('%Y年%m月%d日'))
      end
    end

    context "公開期間を指定しない場合" do
      before do
        @genre = create(:genre, section: @section)
        @page = create(:page_request, genre: @genre)
        @page_content = @page.request_content
        @page_content.begin_date = nil
        @page_content.end_date = nil
        @mail = Susanoo::PageNotifyMailer.publish_request(@authorizer, @page_content)
      end

      it "公開期間が記載されないこと" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include("公開期間(なし)")
      end
    end

    context "公開開始日のみ指定する場合" do
      before do
        @time = Time.new(2013,4,1,12, 0)
        @genre = create(:genre, section: @section)
        @page = create(:page_request, genre: @genre)
        @page_content = @page.request_content
        @page_content.begin_date = @time
        @page_content.end_date = nil
        @mail = Susanoo::PageNotifyMailer.publish_request(@authorizer, @page_content)
      end

      it "公開開始日のみ記載されること" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include("公開期間(#{@time.strftime("%Y年%m月%d日 %H:%M")} 〜)")
      end
    end

    context "公開期間を指定する場合" do
      before do
        @genre = create(:genre, section: @section)
        @page = create(:page_request, genre: @genre)
        @page_content = @page.request_content
        @page_content.begin_date = Time.new(2013,4,1,12, 0)
        @page_content.end_date = Time.new(2014,4,1,12, 0)
        @mail = Susanoo::PageNotifyMailer.publish_request(@authorizer, @page_content)
      end

      it "公開開始日のみ記載されること" do
        expect(@mail.body.raw_source.encode('UTF-8', 'iso-2022-jp')).to include("公開期間(#{@page_content.begin_date.strftime("%Y年%m月%d日 %H:%M")} 〜 #{@page_content.end_date.strftime("%Y年%m月%d日 %H:%M")})")
      end
    end
  end


  describe 'cancel_request' do
    before do
      @genre = create(:genre, section: @section)
      @page = create(:page_request, genre: @genre)
      @page_content = @page.request_content
      @mail = Susanoo::PageNotifyMailer.cancel_request(@authorizer, @page_content, "susanoo@example.com")
    end

    it "メールを送信できること" do
      @mail.deliver!
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "件名が正しいこと" do
      mail_subject = NKF.nkf('-mw', @mail.subject)
      expect(mail_subject).to eq("CMS #{I18n.t('mail.page_notify.cancel_request.subject')}(#{@page.title})")
    end

    it "送信先が正しいこと" do
      expect(@mail.to).to eq(["susanoo@example.com"])
    end
  end

  describe 'publish_reject' do
    before do
      @genre = create(:genre, section: @section)
      @page = create(:page_request, genre: @genre)
      @page_content = @page.request_content
      @page_content.email = 'susanoo'
      @mail = Susanoo::PageNotifyMailer.publish_reject(@editor, @page_content)
    end

    it "メールを送信できること" do
      @mail.deliver!
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "件名が正しいこと" do
      mail_subject = NKF.nkf('-mw', @mail.subject)
      expect(mail_subject).to eq("CMS #{I18n.t('mail.page_notify.publish_reject.subject')}(#{@page.title})")
    end

    it "送信先が正しいこと" do
      expect(@mail.to).to eq(["#{@page_content.email}@#{Settings.mail.domain}"])
    end
  end

  describe 'publish' do
    before do
      @genre = create(:genre, section: @section)
      @page = create(:page_request, genre: @genre)
      @page_content = @page.request_content
      @page_content.email = 'susanoo'
      @mail = Susanoo::PageNotifyMailer.publish(@editor, @page_content)
    end

    it "メールを送信できること" do
      @mail.deliver!
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "件名が正しいこと" do
      mail_subject = NKF.nkf('-mw', @mail.subject)
      expect(mail_subject).to eq("CMS #{I18n.t('mail.page_notify.publish.subject')}(#{@page.title})")
    end

    it "送信先が正しいこと" do
      expect(@mail.to).to eq(["#{@page_content.email}@#{Settings.mail.domain}"])
    end
  end

  describe 'top_news_status_request' do
    before do
      @genre = create(:genre, section: @section)
      @page = create(:page_request, genre: @genre)
      @page_content = @page.request_content
      @page_content.email = 'susanoo'
      @mail = Susanoo::PageNotifyMailer.top_news_status_request(@page_content)
    end

    it "メールを送信できること" do
      @mail.deliver!
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "件名が正しいこと" do
      mail_subject = NKF.nkf('-mw', @mail.subject)
      expect(mail_subject).to eq("CMS #{I18n.t('mail.page_notify.top_news_status_request.subject')}(#{@page.title})")
    end

    it "送信先が正しいこと" do
      expect(@mail.to).to eq([@authorizer.mail])
    end
  end

  describe 'top_news_status_reject' do
    let(:pc_email) { 'susanoo' }

    before do
      @genre = create(:genre, section: @section)
      @page = create(:page_request, genre: @genre)
      @page_content = @page.request_content
      @page_content.email = pc_email
      @mail = Susanoo::PageNotifyMailer.top_news_status_reject(@editor, @page_content)
    end

    it "メールを送信できること" do
      @mail.deliver!
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "件名が正しいこと" do
      mail_subject = NKF.nkf('-mw', @mail.subject)
      expect(mail_subject).to eq("CMS #{I18n.t('mail.page_notify.top_news_status_reject.subject')}(#{@page.title})")
    end

    it "送信先が正しいこと" do
      expect(@mail.to).to match_array([@authorizer.mail, "#{pc_email}@#{domain}"])
    end
  end


  describe 'top_news_status_yes' do
    let(:pc_email) { 'susanoo' }

    before do
      @genre = create(:genre, section: @section)
      @page = create(:page_request, genre: @genre)
      @page_content = @page.request_content
      @page_content.email = pc_email
      @mail = Susanoo::PageNotifyMailer.top_news_status_yes(@editor, @page_content)
    end

    it "メールを送信できること" do
      @mail.deliver!
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "件名が正しいこと" do
      mail_subject = NKF.nkf('-mw', @mail.subject)
      expect(mail_subject).to eq("CMS #{I18n.t('mail.page_notify.top_news_status_yes.subject')}(#{@page.title})")
    end

    it "送信先が正しいこと" do
      expect(@mail.to).to match_array([@authorizer.mail, "#{pc_email}@#{domain}"])
    end
  end
end
