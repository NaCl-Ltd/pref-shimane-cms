class Susanoo::GenresController < ApplicationController
  include Concerns::Susanoo::GenresController

  before_action :reject_event_genre, only: %i(edit new)

  # ブログに関するジャンルを対象としているものは、viewを差し替える。
  def reject_event_genre
    template = "event_calendar/susanoo/genres/reject_event_genre"
    if @genre.try(:event?)
      return render template
    elsif params[:parent_id] && ::Genre.find(params[:parent_id]).try(:event?)
      return render template
    end
  end
end
