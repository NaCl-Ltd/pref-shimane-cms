class Susanoo::GenresController < ApplicationController
  include Concerns::Susanoo::GenresController

  before_action :reject_blog_genre, only: %i(edit new)

  # ブログに関するジャンルを対象としているものは、viewを差し替える。
  def reject_blog_genre
    template = "blog_management/susanoo/genres/reject_blog_genre"
    if @genre.try(:blog_folder?)
      return render template
    elsif params[:parent_id] && ::Genre.find(params[:parent_id]).try(:blog_folder?)
      return render template
    end
  end
end
