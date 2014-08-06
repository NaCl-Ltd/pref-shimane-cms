# -*- coding: utf-8 -*-

class Word < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :base
  validates_presence_of :text
  validates_uniqueness_of :base
  validates_format_of :base, with: /\A[^\s!-~　]*\z/
  validate :base_for_invalid_chars_validation
  validates_format_of :text, with: /\A[ぁ-ん゛ァ-ヶー]*\z/

  before_save   :convert_text_to_katakana
  after_save    :update_dictionary
  after_destroy :update_dictionary

  def set_attributes(params, current_user)
    self.base = params[:word][:base]
    self.text = params[:word][:text]
    self.user = current_user
  end

  def self.get_paginate(params)
    query = {}
    if params[:query_text]
      cond = BrowsingSupport::Filter.h2k(params[:query_text]).split.collect{|e|
        ['text LIKE ?', "#{e}%"]
      }
      conditions = [cond.collect{|i| i[0]}.join(' OR '), *cond.collect{|i| i[1]}]
      search = true
    elsif params[:query_base]
      query[:query_base] = params[:query_base]
      if params[:search]
        conditions = ['base LIKE ?', "%#{params[:query_base]}%"]
        query[:search] = 'search'
      else
        conditions = ['base LIKE ?', "#{params[:query_base]}%"]
        query[:prefix_search] = 'prefix_search'
      end
      search = true
    else
      conditions = nil
      search = false
    end
    words = Kaminari.paginate_array(self.where(conditions).order(:text))
      .page(params[:page])
      .per(10)
    return words, search, query
  end

  def self.last_modified
    cn = %{"#{self.table_name}"."updated_at"}
    self.order("#{cn} desc").select(:updated_at).first.try(:updated_at) || Time.at(0)
  end

  def self.update_dictionary
    File.open("#{dicdir}/user.csv", 'w', encoding: 'euc-jp') do |userdic|
      all.each do |word|
        userdic.puts NKF.nkf('-We', "#{word.base},,,3000,名詞,一般,*,*,*,*,#{word.base},#{word.text},#{word.text},1/1,1C")
      end
    end
    run_mecab_dict_index
  end

  def self.run_mecab_dict_index(options = {})
    cmd = []
    cmd << Settings.browsing_support.voice_synthesis.mecab_dict_index
    cmd << Settings.browsing_support.voice_synthesis.mecab_dict_index_options.to_h.with_indifferent_access.merge(options).to_a
    system %{#{cmd.join(' ')} > /dev/null 2>&1}
  end

  def text_2h
    return self.text if self.text.blank?
    BrowsingSupport::Filter.k2h(self.text)
  end

  def editable_by?(user)
    user.admin? ||
      (user.section_id && self.user.try(:section_id) == user.section_id)
  end

  def self.dicdir
    Settings.browsing_support.dicdir
  end

  private

  def convert_text_to_katakana
    unless self.text.blank?
      self.text = BrowsingSupport::Filter.h2k(self.text)
    end
  end

  def base_for_invalid_chars_validation
    invalid_chars_validation(:base, self.base)
  end

  def invalid_chars_validation(attr, value)
    invalid_chars = Susanoo::Filter.non_japanese_chars(value) || []
    unless invalid_chars.blank?
      chars = invalid_chars.map{|c| '&#%d;' % c.ord}.join(',')
      errors.add(attr, :invalid_chars, chars: chars)
    end
  end

  def update_dictionary
    return if Rails.env.test?

    self.class.update_dictionary
  end
end
