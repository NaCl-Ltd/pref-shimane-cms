module Concerns::Genre::Association
  extend ActiveSupport::Concern
  include ActiveRecord::SkipCallbacks

  included do
    has_many :pages, -> {order('name, pages.id')},
      dependent: :destroy

    belongs_to :section

    belongs_to :original, class_name: 'Genre',
      foreign_key: 'original_id', inverse_of: :copies

    has_many :copies, class_name: 'Genre',
      foreign_key: 'original_id', dependent: :destroy, inverse_of: :original

    has_many :web_monitors,
      dependent: :destroy

    has_many :section_news,
      dependent: :destroy

    acts_as_tree order: "no, original_id desc, id"

    acts_as_list column: :no, scope: :parent_id
  end
end
