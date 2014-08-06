module Concerns::Susanoo::InfosController
  extend ActiveSupport::Concern

  included do

    # GET /susanoo/infos/1
    def show
      @info = Info.find(params[:id])
      render action: "show", layout: false
    end
  end
end
