module AdvertisementManagement
  module Helpers
    module AdvertisementsHelper
      # === 広告用のJobがあるか？
      def advertisement_job_exists?
        Advertisement.advertisement_job_exists?
      end

      # === 広告の処理状態、または広告の状態を返す
      def state_or_processing(advertisement)
        return advertisement.advertisement_list.state_label if advertisement_job_exists? && advertisement.advertisement_list
        advertisement.state_label
      end
    end
  end
end
