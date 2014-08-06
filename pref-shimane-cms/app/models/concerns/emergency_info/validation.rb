module Concerns::EmergencyInfo::Validation
  extend ActiveSupport::Concern

  included do
    validate :display_start_datetime_valid?
    validate :display_end_datetime_valid?
    validates :content, presence: true
  end

  private

    def display_start_datetime_valid?
      if display_start_datetime >= display_end_datetime
        errors.add(
          :display_start_datetime,
          I18n.t('activerecord.errors.models.emergency_info.attributes.display_start_datetime', time: display_end_datetime.strftime(I18n.t('date.formats.public_term')))
        )
      end
    end

    def display_end_datetime_valid?
      if display_start_datetime >= display_end_datetime
        errors.add(
          :display_end_datetime,
          I18n.t('activerecord.errors.models.emergency_info.attributes.display_end_datetime', time: display_start_datetime.strftime(I18n.t('date.formats.public_term')))
        )
      end
    end

end
