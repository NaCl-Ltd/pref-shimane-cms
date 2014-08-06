module Susanoo::PagesHelper

  #
  #=== 携帯向けコンテンツの有無を表示する
  #
  def page_contents_has_mobile_text(page_content)
    if page_content.present? && page_content.mobile.present?
      t(".mobile.exist")
    else
      t(".mobile.not_exist")
    end
  end

  #
  #=== 所属向け掲載情報を表示する
  #
  def page_contents_section_news_text(page_content)
    return unless page_content
    text = if page_content.section_news
      _text = t("shared.section_news.#{page_content.section_news_name}")
      if page_content.news_title && page_content.page.title != page_content.news_title
        _text += "(#{page_content.news_title})"
      end
      _text
    else
      t("shared.section_news.no")
    end
    h text
  end

  #
  #=== ページ編集担当者の連絡先を表示する
  #
  def page_contents_contact_text(page_content)
    return unless page_content
    text = ""
    text = page_content.user_name
    text << " (#{page_content.tel})" if page_content.tel.present?
    text << " #{page_content.email_with_domain}" if page_content.email.present?
    h text
  end

  #
  #=== ページ一覧ソート用のHTMLを生成する
  #
  def link_to_sort(column, search_params)
    org_direction = 'ASC'
    link_params = search_params.deep_dup
    if link_params[:search].present?
      if link_params[:search][:order_column].present? && link_params[:search][:order_column] ==  column
        org_direction = link_params[:search][:order_direction]
        link_params[:search][:order_direction] = link_params[:search][:order_direction] == 'ASC' ? 'DESC' : 'ASC'
      else
        link_params[:search][:order_column] = column
        link_params[:search][:order_direction] = 'DESC'
      end
    else
      link_params[:search] = {}
      link_params[:search][:order_column] = column
      link_params[:search][:order_direction] = 'DESC'
    end

    if org_direction == 'ASC'
      link_to(url_for(link_params), class: 'sort', remote: true) do
        content_tag('span', nil, class: 'dropup caret').html_safe
      end
    else
      link_to(url_for(link_params), class: 'sort', remote: true) do
        content_tag('span', nil, class: 'dropdown caret').html_safe
      end.html_safe
    end
  end

  #
  #=== ページタイトルとページの状態を併せて返す
  #
  def page_title_with_status(page_content_id)
    page_content = PageContent.find(page_content_id)
    status =
      case
      when page_content.editing?
        I18n.t("susanoo.pages.select_copy_page_footer.label.unpublished")
      else
        I18n.t("susanoo.pages.select_copy_page_footer.label.published")
      end

    page_content.page.title + "（#{status}）"
  end
end
