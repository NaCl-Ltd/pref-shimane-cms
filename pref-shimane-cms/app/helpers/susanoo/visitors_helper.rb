module Susanoo::VisitorsHelper
  include Susanoo::PluginHelper

  def page_content_for_layout(page_view)
    if !page_view.external_uri_page?
      unless page_view.mobile
        if page_view.genre_top_layout?
          # Genreのトップ画面を表示する
          # 該当genreがsection_topい設定されておらず、作成されたpageも存在しない場合
          render partial: '/susanoo/visitors/contents/genre_top'
        elsif page_view.section_top_layout?
          # Sectionのトップ画面をcontentにセット
          # sectionのtop_genre_idに該当するgenreの場合のみ
          render partial: '/susanoo/visitors/contents/section_top'
        else
          page_view.content
        end
      else
        page_view.mobile_content
      end
    else
      # 外部URIを表示するHTMLをcontentにセットする
      render partial: '/susanoo/visitors/contents/external_uri'
    end
  end

  def top_photo_link
    Settings.top_photo_link || Settings.base_uri
  end

  def top_new_rdf_path
    page_path = Settings.top_news_page.to_s
    page_path.sub(/\.[^\.]*$/, '') + '.rdf'
  end
end
