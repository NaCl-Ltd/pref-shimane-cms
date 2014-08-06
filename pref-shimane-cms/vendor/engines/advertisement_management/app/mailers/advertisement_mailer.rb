module AdvertisementManagement
  module Susanoo
    class AdvertisementMailer < ActionMailer::Base
      default  charset: 'ISO-2022-JP'

      # expired advertisement notify mail
      def expired_advertisement(advertisement)
        @url = URI.join(Settings.mail.uri, susanoo_advertisements_path).to_s
        @name = advertisement.name

        mail(
             subject: "CMSバナー広告掲載処理",
             from: Settings.super_user_mail,
             to: Settings.super_user_mail,
             date: Time.now,
             encoding: 'iso-2022-jp'
             )
      end
    end
  end
end
