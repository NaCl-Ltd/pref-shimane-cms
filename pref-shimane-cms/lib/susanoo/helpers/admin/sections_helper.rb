module Susanoo
  module Helpers::Admin::SectionsHelper
    # === Genreのoptionタグの生成
    # * genres - Genreのインスタンス配列
    # * selected - selectedの値
    # * options
    # * <tt>:not_specified_blank</tt> - falseを設定すると"指定無し"を表示しない
    def options_for_select_with_second_genres(selected=nil)
      genres = Genre.top_genre.children
      list = genres.map{|g|[g.title, g.id]}
      list.unshift([I18n.t("shared.not_select"), 0])
      options_for_select(list, selected)
    end
  end
end
