module Susanoo
  # coding: utf-8
  class PageNotifyMailer < ActionMailer::Base
    default charset: "iso-2022-jp"
    DOMAIN = "@#{Settings.mail.domain}"

    #
    #=== 承認依頼
    #
    def publish_request(user, page_content)
      @section = user.section
      subject = I18n.t("mail.page_notify.publish_request.subject")
      users = user.section.users.select(&:authorizer?)
      to_mail = users.map(&:mail).select{ |mail| mail.present? }.uniq

      if to_mail.blank?
        self.message.perform_deliveries = false
      else
        create_mail_body(page_content, subject, to_mail)
      end
    end

    #
    #=== 停止依頼
    #
    def cancel_request(user, page_content, to_mail)
      @section = user.section
      subject = I18n.t("mail.page_notify.cancel_request.subject")
      create_mail_body(page_content, subject, to_mail)
    end

    #
    #=== 却下
    #
    def publish_reject(user, page_content)
      @section = user.section
      subject = I18n.t("mail.page_notify.publish_reject.subject")
      to_mail = Array.new
      if page_content.email.present?
        to_mail << page_content.email + set_domain_part(@section)
        create_mail_body(page_content, subject, to_mail)
      else
        # メール送信を行わない場合にセットする。
        self.message.perform_deliveries = false
      end
    end

    #
    #== 承認
    #
    def publish(user, page_content)
      @section = user.section
      subject = I18n.t("mail.page_notify.publish.subject")
      to_mail = ""
      if page_content.email.present?
        to_mail = page_content.email + set_domain_part(@section)
        create_mail_body(page_content, subject, to_mail)
      else
        # メール送信を行わない場合にセットする。
        self.message.perform_deliveries = false
      end
    end

    #
    #=== トップ新着掲載依頼
    #
    def top_news_status_request(page_content)
      @section = page_content.page.genre.section
      users = @section.users.select(&:authorizer?)
      to_mail = users.map(&:mail).select{ |mail| mail.present? }.uniq
      if to_mail.blank?
        self.message.perform_deliveries = false
      else
        subject = I18n.t("mail.page_notify.top_news_status_request.subject")
        create_mail_body(page_content, subject, to_mail)
      end
    end

    #
    #=== トップ新着掲載 REJECT
    #
    def top_news_status_reject(user, page_content)
      subject = I18n.t("mail.page_notify.top_news_status_reject.subject")
      @section = page_content.page.genre.section
      to_mail = @section.users.select(&:authorizer?).map(&:mail)
      if page_content.email.present?
        to_mail << page_content.email + set_domain_part(@section)
      end
      if to_mail.empty?
        # メール送信を行わない場合にセットする。
        self.message.perform_deliveries = false
      else
        create_mail_body(page_content, subject, to_mail)
      end
    end

    #
    #=== トップ新着掲載 YES
    #
    def top_news_status_yes(user, page_content)
      subject = I18n.t("mail.page_notify.top_news_status_yes.subject")
      @section = page_content.page.genre.section
      to_mail = @section.users.select(&:authorizer?).map(&:mail)
      if page_content.email.present?
        to_mail << page_content.email + set_domain_part(@section)
      end
      if to_mail.empty?
        # メール送信を行わない場合にセットする。
        self.message.perform_deliveries = false
      else
        create_mail_body(page_content, subject, to_mail)
      end
    end

  private
    #
    #=== 本文作成
    #
    def create_mail_body(page_content, subject, to)
      @page_content = page_content

      @time = Time.now
      @begin_date = page_content.begin_date.strftime('%Y年%m月%d日 %H:%M') rescue nil
      @end_date = page_content.end_date.strftime('%Y年%m月%d日 %H:%M') rescue nil
      @url = URI.join(Settings.mail.uri, page_content.page.show_url).to_s

      mail(
        subject: "CMS #{subject}(#{page_content.page.title})",
        from: Settings.super_user_mail,
        to: to.class == String ? to : to.join(";"),
        date: @time,
        encoding: 'iso-2022-jp'
      )
    end

    #
    #=== メールアドレスのドメインパート設定
    #
    def set_domain_part(section)
      return DOMAIN if section.domain_part.blank?
      return "@" + section.domain_part
    end
  end
end
