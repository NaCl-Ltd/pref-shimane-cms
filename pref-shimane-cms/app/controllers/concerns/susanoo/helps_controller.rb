module Concerns::Susanoo::HelpsController
  extend ActiveSupport::Concern

  included do
    before_action :login_required

    layout 'explore'

    def index
    end

    def treeview
      render json: ::HelpCategory.category_and_help_for_treeview(id: params[:id], expanded: params[:expanded_id])
    end

    def show
      @help = ::Help.includes(:help_content).find(params[:id])
      render partial: 'show'
    end

    def search
      render json: ::HelpCategory.category_and_help_search(params[:keyword])
    end
  end
end

