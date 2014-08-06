require_dependency "lost_link_check/application_controller"

module LostLinkCheck
  module Susanoo
    class LostLinksController < ApplicationController
      before_action :login_required
      before_action :set_lost_link, only: [:destroy]

      #
      #=== リンク切れ一覧
      #
      def index
        lost_links = LostLink.manages(current_user).order("id DESC")
        @insides = lost_links.insides
        @outsides = lost_links.outsides
      end

      #
      #=== 削除処理
      #
      def destroy
        @lost_link.destroy

        redirect_to susanoo_lost_links_path
      end

      private

        #
        #=== @lost_linkをセット
        #
        def set_lost_link
          @lost_link = LostLink.find(params[:id])
        end

    end
  end
end

