module Susanoo::PageContentsHelper
  #
  #=== 未公開ページの状態セレクトボックスを表示する
  #
  def private_admission_select(page_content, name, options = {})
    collection = PageContent.private_status_list(current_user).map do |i|
      [PageContent.admission_label(i), i]
    end
    select_tag(name, options_for_select(collection, selected: page_content.admission_local)).html_safe
  end

  #
  #=== 公開ページの状態セレクトボックスを表示する
  #
  def public_admission_select(page_content, name, options = {})
    if page_content.begin_date && page_content.begin_date > Time.zone.now
      collection = [
        [t("susanoo.page_contents.edit_public_page_status.to_publish"), PageContent.page_status[:publish]],
        [t("susanoo.page_contents.edit_public_page_status.to_reject"), PageContent.page_status[:reject]]
      ]
    else
      collection = PageContent.public_status_list(current_user).map do |i|
        [PageContent.admission_label(i), i]
      end
    end

    select_tag(name, options_for_select(collection, selected: page_content.admission_local)).html_safe
  end

  def display_mail_domain
    return Settings.mail.domain if current_user.section.domain_part.blank?
    return current_user.section.domain_part
  end

end
