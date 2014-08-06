module Concerns::EmergencyInfo::Method
  extend ActiveSupport::Concern

  included do
    scope :publishes, -> {where("display_start_datetime <= ? AND display_end_datetime >= ?", Time.now, Time.now)}
  end

  module ClassMethods
    def stop_public
      now_time = DateTime.now
      emergency_info = self.first
      if emergency_info &&
          now_time.between?(emergency_info.display_start_datetime, emergency_info.display_end_datetime)
        emergency_info.update(display_end_datetime: now_time)
      end
    end

    #=== 公開中の緊急情報を１件返す。
    def public_info
      EmergencyInfo.publishes.order("id desc").first
    end
  end
end
