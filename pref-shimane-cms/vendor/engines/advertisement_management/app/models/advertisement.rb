# -*- coding: utf-8 -*-
class Advertisement < ActiveRecord::Base
  INSIDE_TYPE = 1
  OUTSIDE_TYPE = 2
  TOPPAGE_TYPE = 3

  NOT_PUBLISHED = 1
  PUBLISHED = 2

  STATE = { PUBLISHED => 'published', NOT_PUBLISHED => 'unpublished'}
  SHOW_IN_HEADER = { true => "show", false => 'hidden'}
  SIDE_TYPE = {INSIDE_TYPE => 'pref', OUTSIDE_TYPE => 'corp', TOPPAGE_TYPE => 'toppage'}

  IMAGE_DIR = "files/advertisement/#{Rails.env}"
  PUBLIC_IMAGE_DIR = "#{Rails.root}/public/images/advertisement/"
  JAVASCRIPT_FILE = "#{Rails.root}/public/javascripts/banner.js"

  DISPLAY_PUBLIC_IMAGE_DIR_PATH = "/advertisement.data/"

  EXT_RE = /\A\.(jpe?g|png|gif)\z/i

  has_one :advertisement_list
  has_attached_file :image,
    path: ":rails_root/files/advertisement/#{Rails.env}/:id.:extension",
    url: "/files/advertisement/#{Rails.env}/:id.:extension",
    default_url: "/files/advertisement/#{Rails.env}/:id.:extension"

  scope :insides, -> {where("advertisements.side_type = ?", INSIDE_TYPE)}
  scope :outsides, -> {where("advertisements.side_type = ?", OUTSIDE_TYPE)}
  scope :toppages, -> {where("advertisements.side_type = ?", TOPPAGE_TYPE)}
  scope :publishes, -> {where("advertisements.state = ?", PUBLISHED)}
  scope :not_publishes, -> {where("advertisements.state = ?", NOT_PUBLISHED)}
  scope :expired, -> {where("advertisements.end_date < ?", Time.now)}

  validates :side_type, presence: {message: I18n.t("activerecord.errors.messages.non_select")}
  validates :name, presence: true, uniqueness: true
  validates :alt, presence: true
  validates :url, presence: true

  validates_attachment_size :image, less_than: 50.kilobytes, unless: lambda { self.toppage? }
  validates_attachment_content_type :image, content_type: ['image/jpeg', 'image/jpg', 'image/pjpeg', 'image/png', 'image/gif']
  validates_attachment_presence :image

  validate :validate_begin_date_and_end_date

  # === 公開日に関するvalidation
  def validate_begin_date_and_end_date
    if self.begin_date && self.end_date
      if self.begin_date > self.end_date
        end_col = I18n.t("activerecord.attributes.advertisement.end_date")
        errors.add(:begin_date, I18n.t("errors.messages.is_behind_from_date", finish: end_col))
      end
    end
  end


  # === 県広告
  def self.pref_advertisements
    self.insides.order("state DESC, pref_ad_number")
  end

  # === 企業広告
  def self.corp_advertisements
    self.outsides.order("state DESC, corp_ad_number")
  end

  # === トップページ上部
  def self.toppage_advertisements
    self.toppages.order("state DESC, toppage_ad_number")
  end

  # === 公開中の県広告
  def self.pref_published
    Advertisement.insides.where("state = 2").order("pref_ad_number")
  end

  # === 公開中の企業広告
  def self.corp_published
    Advertisement.outsides.where("state = 2").order("corp_ad_number")
  end

  # === 公開中のトップページ上部バナー
  def self.toppage_published
    Advertisement.toppages.where("state = 2").order("toppage_ad_number")
  end

  STATE.each do |k, v|
    define_method("#{v}?") do
      self.state == k
    end
  end

  # 有効期限切れ？
  def expired?
    Time.now > self.end_date
  end

  SIDE_TYPE.each do |k, v|
    define_method("#{v}?") do
      self.side_type == k
    end
  end

  # === 状態名を表示
  def state_label
    I18n.t("activerecord.attributes.advertisement.state_label.#{STATE[self.state]}")
  end

  # === 広告の表示有無
  def show_in_header_label
    flg = !!self.show_in_header
    I18n.t("activerecord.attributes.advertisement.show_in_header_label.#{SHOW_IN_HEADER[flg]}")
  end

  # === 種別名表示
  def side_type_label
    I18n.t("activerecord.attributes.advertisement.side_type_label.#{SIDE_TYPE[self.side_type]}")
  end

  # === 画像の削除処理
  def delete_img
    path = self.image.path
    begin
      FileUtils.rm(path) if File.exist?(path) && !File.directory?(path)
    rescue => e
      logger.error("Error while deleteing image: #{e.message}")
    end
  end

  # === AdvertisementListをセット
  def self.resetting_list
    AdvertisementList.transaction do
      AdvertisementList.delete_all
      Advertisement.all.each do |ad|
        ad.advertisement_list = AdvertisementList.create(
          state: ad.state,
          pref_ad_number: ad.pref_ad_number,
          corp_ad_number: ad.corp_ad_number,
          toppage_ad_number: ad.toppage_ad_number
        )
      end
    end
  end

  # === 画像の表示パスを返す。
  def display_public_image_path
    File.join(DISPLAY_PUBLIC_IMAGE_DIR_PATH, self.id.to_s + File.extname(self.image.path))
  end

  # === 公開していてかつ有効期限の切れた広告をメールで知らせる
  def self.send_expired_advertisement_mail
    self.publishes.expired.each do |advertisement|
      ::AdvertisementManagement::Susanoo::AdvertisementMailer.expired_advertisement(advertisement).deliver
    end
  end

  # === 広告用のJobがある否かを返す。
  def self.advertisement_job_exists?
    Job.where("action = ?", "move_banner_images").exists?
  end

  # === 公開設定が行える状態であるか否かを返す。
  def self.state_editable?
    !advertisement_job_exists? &&
      toppage_advertisements.exists?
  end
end

