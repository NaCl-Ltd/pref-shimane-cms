#
#= Page の バリデーションを管理するモジュール
#
module Concerns::Page::Validation
  extend ActiveSupport::Concern

  included do
    validates :genre_id, presence: true
    validates :name, presence: true, uniqueness: {scope: :genre_id}, format: {with: /\A[a-z0-9\-\_]*\z/i}
    validates :title, presence: true, uniqueness: {scope: :genre_id}

    # 新規作成時にgenreと紐付けずに入力されることがあり、その場合はチェックしない(他のエラーになるので、構わない）
    # 将来的にsusanoo?が廃止される可能性があるため、susanoo?が呼べない場合はtrueとする（本来そうなった場合は、if自体を削除）
    validates :title, length: { maximum: 35 }, if: lambda { |r| r.genre.try(:section) && (!r.genre.section.respond_to?(:susanoo?) || r.genre.section.susanoo?) }, on: :create

    validate :validate_title
    validate :only_index_valid, on: :create

    #
    #=== ページタイトルを検証する
    #
    def validate_title
      invalid_chars = Susanoo::Filter::non_japanese_chars(title)
      if invalid_chars.present?
        errors.add(:title, :invalid)
      end
    end

    #
    #=== 所属フォルダ配下のフォルダには、index以外のページは作成できないようにする
    #
    def only_index_valid
      if section && section.try(:susanoo?)
        genres = genre.ancestors.reverse
        genres << genre
        genre_ids = genres.select {|g| !g.top_genre? }.map {|g| g.id }

        if Section.exists?(top_genre_id: genre_ids) && self.name != 'index'
          errors.add(:name, I18n.t('activerecord.errors.models.page.only_index'))
        end
      end
    end
  end
end
