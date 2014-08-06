#
#= User の属性、アソシエーションを管理するモジュール
#
module Concerns::Page::Association
  extend ActiveSupport::Concern

  included do
    belongs_to :genre, class_name: 'Genre'
    has_many :section_news, class_name: 'SectionNews',
      dependent: :destroy

    has_many :contents, -> { order('page_contents.id DESC') },
      class_name: 'PageContent', dependent: :destroy

    has_many :revisions, -> { order('page_revisions.id DESC') },
      class_name: 'PageRevision',
      dependent: :destroy

    has_one :lock, class_name: 'PageLock', dependent: :delete

    belongs_to :original, class_name: 'Page',
      foreign_key: 'original_id', inverse_of: :copies

    has_many :copies, class_name: 'Page',
      foreign_key: 'original_id', dependent: :destroy, inverse_of: :original

    has_many :lost_links,
      dependent: :destroy

    accepts_nested_attributes_for :contents

    attr_accessor :template_id, :copy_id

    paginates_per 10
  end
end
