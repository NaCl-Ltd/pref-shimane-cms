class Susanoo::PagesController < ApplicationController
  include Concerns::Susanoo::PagesController

  before_action :reject_blog_page, only: %i(show edit new create)

  # ブログに関するページを対象としているものは、viewを差し替える。
  # NOTE: インデックスページに関しては、通常ページと同じように編集できるようにする
  def reject_blog_page
    template = "blog_management/susanoo/pages/reject_blog_page"

    if @page
      if @page.genre.blog_folder? && @page.name != "index"
        # show, edit, createのとき
        # genreを見るのは、ブログとは関係無い通常ページも弾くため
        return render template
      end
    elsif params[:genre_id] && ::Genre.find(params[:genre_id]).try(:blog_folder?)
      # indexページはnewされないため、indexページを考慮しなくてよい
      return render template
    elsif params[:page].try(:[], :genre_id)
      genre = ::Genre.where(id: params[:page][:genre_id])
      if genre.present? && genre.first.blog_folder?
        # createのとき
        # genre_idを指定しないでnewを実行することがあるため、createアクションになって初めて
        # ブログフォルダかどうか判断できる
        # indexページはcreateされないため、indexページを考慮しなくてよい
        return render template
      end
    end
  end
end
