require "advertisement_management/susanoo/exports/banner_creator"

module AdvertisementManagement
  module Susanoo
    module Export

      extend ActiveSupport::Concern

      included do
        action_method *%i(
            move_banner_images
          )
      end

      #
      #=== move_banner_images
      #
      # Jobのアクションに'move_banner_images'が入っている時に、sendにより呼び出される
      def move_banner_images(arg=nil)
        banner_creator = AdvertisementManagement::Susanoo::Exports::BannerCreator.new
        banner_creator.make
      end

    end
  end
end
