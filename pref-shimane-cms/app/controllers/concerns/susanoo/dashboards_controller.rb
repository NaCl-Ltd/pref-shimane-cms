#
#= トップページ表示用コントローラのアクションを定義するモジュール
#
module Concerns::Susanoo::DashboardsController
  extend ActiveSupport::Concern

  included do
    before_filter :login_required, only: %w(index)

    #
    #== トップページを表示する
    #
    def index
      @infos = ::Info.order(last_modified: :desc).all
      @top_genre_id = Genre.top_genre.try(:id)
    end
  end
end
