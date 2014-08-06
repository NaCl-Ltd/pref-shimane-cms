module Susanoo
  module Accessibility
    class Button < Base
      def validate(doc)
        doc.xpath("//button").each do |node|
          invalid_chars = Susanoo::Filter::non_japanese_chars(node[:value])
          if invalid_chars.present?
            error('E_7_1', node)
          end
        end
        @messages
      end
    end
  end
end
