# -*- coding: utf-8 -*-
module Concerns::Genre::Validation
  extend ActiveSupport::Concern

  included do
    validates :title, presence: true, format: { without: /\A\s*\z/ }
    validates :name, uniqueness: {scope: :parent_id }
    validates :deletable, inclusion: { in: [true, false] }

    validate :validate_name, :validate_title

    # 一時的に所属TOPフォルダへのフォルダ作成を有効にする
    # validate :parent_top_genre_valid, on: :create

    #
    #=== タイトル検証
    #
    def validate_title
      invalid_chars = Susanoo::Filter::non_japanese_chars(title)
      if invalid_chars.present?
        errors.add(:title, :invalid)
      end
    end

    #
    #=== フォルダ名検証
    # トップフォルダ以外は半角英数字のみ許可
    #
    def validate_name
      if path != '/'
        errors.add(:name, :invalid) unless /^[a-zA-Z0-9\-\_]+$/ =~ name
      end

      if self.new_record?
        if /(^\_[a-zA-Z0-9\-\_]+$|javascripts|stylesheets|images|contents|backnumbers|blog_cms|event_calendar)/ =~ name
          errors.add(:name, :initial_invalid)
        end
      end
    end

    #
    #=== 所属のTOPフォルダへ、フォルダを作成出来ないようにする　
    #
    def parent_top_genre_valid
      if parent_genre = self.parent
        if parent_genre.section && parent_genre.section.try(:susanoo?)
          if Section.exists?(top_genre_id: parent_genre.id)
            errors.add(:parent_id, I18n.t('activerecord.errors.models.genre.parent_top_genre'))
          end
        end
      end
    end
  end
end
