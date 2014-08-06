module Susanoo::Admin::HelpCategoriesHelper

  #=== フォルダのフルパスを表示する
  #
  def help_category_fullpath(help_category, options= {})
    return nil if help_category.nil?

    separator = options[:separator] || " > "
    text = help_category.fullpath.map {|_| _.name }.unshift(t('susanoo.admin.help_categories.index.title')).join(separator)
    text.html_safe
  end
end
