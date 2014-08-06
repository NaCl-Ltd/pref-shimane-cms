module Susanoo
  module Accessibility
    class Text < Base
      #
      # &npsp; が　UTF-8の空白(C2A0)に変換され、機種依存文字チェックに
      # 引っかかるため、UTF-8の空白(C2A0)は&npsp;に変換する
      #
      def validate(doc)
        selector = settings.target.xpath
        nbsp = Nokogiri::HTML("&nbsp;").text
        doc.xpath("#{selector}//text()").each_with_index do |node, i|
          text = node.text.gsub(nbsp, "&nbsp;")
          invalid_chars = Susanoo::Filter::non_japanese_chars(text)
          if invalid_chars.present?
            error('E_6_1', node.parent)
          end
        end

        user_decision('U_6_1', nil)

        @messages
      end
    end
  end
end
