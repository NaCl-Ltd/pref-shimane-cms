class Susanoo::PagesController < ApplicationController
  include Concerns::Susanoo::PagesController

  before_action :reject_event_page, only: %i(show edit new create)

  # イベントに関するページを対象としているものは、viewを差し替える
  # NOTE: インデックスページに関しては、通常ページと同じように編集できるようにする
  def reject_event_page
    template = "event_calendar/susanoo/pages/reject_event_page"

    if @page
      if @page.event? && @page.name != "index"
        # show, edit, createのとき
        # インデックスページの場合は弾かない
        return render template
      end
    elsif params[:genre_id] && ::Genre.find(params[:genre_id]).try(:event?)
      # newのとき
      # この段階ではindexページを作成するつもりなのか判断つかないので、何もしない
    elsif params[:page].try(:[], :genre_id)
      genre = ::Genre.where(id: params[:page][:genre_id])
      if genre.present? && genre.first.event? && params[:page][:name] != "index"
        # createのとき
        # genre_idを指定しないでnewを実行することがあるため、createアクションになって初めて
        # イベントかどうか判断できる
        # ただし、indexページの場合は弾かない
        return render template
      end
    end
  end
end
