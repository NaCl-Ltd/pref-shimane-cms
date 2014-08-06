# -*- coding: utf-8 -*-
class AdvertisementList < ActiveRecord::Base
  NOT_PUBLISHED = 1
  PUBLISHED = 2

  STATE = { PUBLISHED => 'published', NOT_PUBLISHED => 'unpublished' }

  belongs_to :advertisement

  scope :published, ->{ where("advertisement_lists.state = ?", PUBLISHED)}

  # === 公開中の県広告
  def self.pref_published
    order = "advertisement_lists.pref_ad_number"
    AdvertisementList.published.includes(:advertisement).references(:advertisement).merge(Advertisement.insides).order(order)
  end

  # === 公開中の企業広告
  def self.corp_published
    order = "advertisement_lists.corp_ad_number"
    AdvertisementList.published.includes(:advertisement).references(:advertisement).merge(Advertisement.outsides).order(order)
  end

  # === 公開中のトップページ上部バナー
  def self.toppage_published
    order = "advertisement_lists.toppage_ad_number"
    AdvertisementList.published.includes(:advertisement).references(:advertisement).merge(Advertisement.toppages).order(order)
  end

  # === プレビュー用の変数をセット
  def self.set_preview_lists
    prefs, corps = Advertisement::SIDE_TYPE.values.map do |st|
      published_ads = AdvertisementList.send("#{st}_published")
      ads = published_ads.map do |ad|
        attr = ad.advertisement.attributes.merge({
          state: ad.state,
          pref_ad_number: ad.pref_ad_number,
          corp_ad_number: ad.corp_ad_number,
          toppage_ad_number: ad.toppage_ad_number
        })
        Advertisement.new(attr)
      end
      ads
    end
    return prefs, corps
  end

  # === 状態名を表示
  def state_label
    I18n.t("activerecord.attributes.advertisement_list.state_label.#{STATE[self.state]}")
  end
end

class ToppageSelectionError < StandardError; end;
