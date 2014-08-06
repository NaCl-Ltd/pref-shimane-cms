module Susanoo
  module Accessibility
    #
    #=== スタイル属性のチェック
    # font-size の pt、px、exを禁止する
    #
    class Style < Base
      def validate(doc)
        xpath = settings.target.xpath
        doc.xpath("#{xpath}//*[@style]").each_with_index do |e, i|
          styles = e['style'].split(';')
          styles.each do |style|
            values = style.split(':')
            next if values.length < 2
            name  = values[0].downcase
            value = values[1].downcase
            case name
            when 'font-size'
              validate_font_size(e, name, value)
            when 'font'
              validate_font(e, name, value)
            end
          end
        end
        @messages
      end


      private

        #
        #== スタイル font-size のチェック
        #
        def validate_font_size(node, name, value)
          regex = font_size_regex
          args = settings.style.font_size.disabled_units.join(',')
          error('E_4_1', node, args) if value =~ regex
        end

        #
        #== スタイル font のチェック
        #
        def validate_font(node, name, values)
          regex = font_size_regex
          args = settings.style.font_size.disabled_units.join(',')

          values.split(' ').each do |value|
            error('E_4_1', node, args) if value =~ regex
          end
        end


        def font_size_regex
          /^\d+#{settings.style.font_size.disabled_units.join("|")}$/
        end
    end
  end
end
