module Susanoo
  module Accessibility
    class Alt < Base
      def validate(doc)
        selector = settings.target.css
        doc.css("#{selector} img").each_with_index do |e, i|
          alt = e['alt']
          if alt.blank? || alt.gsub(/(\s|　)+/, '').length == 0
            error('E_2_1', e)
          elsif alt.length < settings.alt.minimum || alt.length > settings.alt.maximum
            error('E_2_2', e, settings.alt.minimum, settings.alt.maximum)
          end
        end
        @messages
      end
    end
  end
end
